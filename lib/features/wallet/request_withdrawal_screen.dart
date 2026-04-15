import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_providers.dart';
import 'providers/wallet_withdrawal_providers.dart';
import 'wallet_financial_api.dart';
import 'wallet_feedback.dart';

/// Withdraw wallet balance to bank (IBAN). Fee applies per admin settings.
class RequestWithdrawalScreen extends ConsumerStatefulWidget {
  const RequestWithdrawalScreen({super.key});

  @override
  ConsumerState<RequestWithdrawalScreen> createState() =>
      _RequestWithdrawalScreenState();
}

class _RequestWithdrawalScreenState extends ConsumerState<RequestWithdrawalScreen> {
  final _amountCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, double>? _quote;
  Timer? _quoteDebounce;
  int _quoteGen = 0;

  double? _parseAmount(String raw) {
    final t = raw.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _amountCtrl.dispose();
    _ibanCtrl.dispose();
    _bankCtrl.dispose();
    _countryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _scheduleQuoteRefresh() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _refreshQuote();
    });
  }

  Future<void> _refreshQuote() async {
    final gen = ++_quoteGen;
    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      if (mounted) setState(() => _quote = null);
      return;
    }
    final q = await fetchWithdrawalQuote(amount);
    if (!mounted || gen != _quoteGen) return;
    setState(() => _quote = q);
  }

  Future<void> _submit() async {
    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      await walletShowError(
        context,
        title: 'Amount',
        message: 'Enter a withdrawal amount greater than zero.',
      );
      return;
    }
    final bal = ref.read(walletBalanceProvider).valueOrNull?.available ?? 0;
    if (amount > bal + 1e-9) {
      if (!mounted) return;
      await walletShowError(
        context,
        title: 'Balance',
        message:
            'Withdrawal amount cannot be greater than your available balance '
            '(\$${bal.toStringAsFixed(2)}).',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await createWalletWithdrawal(
        amount: amount,
        iban: _ibanCtrl.text.trim(),
        bankName: _bankCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result.ok) {
        ref.invalidate(walletWithdrawalsProvider);
        ref.invalidate(walletBalanceProvider);
        await walletShowSuccess(
          context,
          message:
              result.data['message']?.toString() ?? 'Request submitted',
        );
        if (!mounted) return;
        context.pop();
        return;
      }
      final msg = result.data['message']?.toString() ?? 'Request failed';
      await walletShowError(context, message: msg);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bal = ref.watch(walletBalanceProvider).valueOrNull?.available ?? 0;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Withdraw to bank'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Available balance: \$${bal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A fee may apply (shown below before you submit). After the transfer is completed at the bank, '
                'funds may take up to 30 days to reach your account.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount to withdraw (USD)',
                  border: OutlineInputBorder(),
                  helperText:
                      'Fee estimate updates shortly after you stop typing.',
                ),
                onChanged: (_) => _scheduleQuoteRefresh(),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _refreshQuote,
                child: const Text('Update fee estimate'),
              ),
              if (_quote != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Fee ${_quote!['fee_percent']!.toStringAsFixed(2)}% → '
                  '\$${_quote!['fee_amount']!.toStringAsFixed(2)} · '
                  'Net \$${_quote!['net_amount']!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _ibanCtrl,
                decoration: const InputDecoration(
                  labelText: 'IBAN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _bankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit withdrawal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
