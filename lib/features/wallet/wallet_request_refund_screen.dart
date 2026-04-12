import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_providers.dart';
import 'providers/wallet_refund_providers.dart';
import 'wallet_refund_api.dart';

/// Form: amount, reason, IBAN, bank, country.
class WalletRequestRefundScreen extends ConsumerStatefulWidget {
  const WalletRequestRefundScreen({super.key});

  @override
  ConsumerState<WalletRequestRefundScreen> createState() => _WalletRequestRefundScreenState();
}

class _WalletRequestRefundScreenState extends ConsumerState<WalletRequestRefundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _ibanCtrl.dispose();
    _bankCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await createWalletRefundRequest(
        amount: amount,
        reason: _reasonCtrl.text.trim(),
        iban: _ibanCtrl.text.trim(),
        bankName: _bankCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
      );
      if (!mounted) return;
      final data = result.data;
      if (result.ok) {
        ref.invalidate(walletRefundRequestsProvider);
        ref.invalidate(walletBalanceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']?.toString() ?? 'Request submitted')),
        );
        context.pop();
        return;
      }
      final msg = data['message']?.toString() ?? 'Request failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
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
        title: const Text('Request bank refund'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Available balance: \$${bal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Refunds are reviewed by our team. Funds are not deducted until the transfer is processed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (USD)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Required';
                    final n = double.tryParse(t);
                    if (n == null || n <= 0) return 'Invalid amount';
                    if (n > bal + 0.0001) return 'Cannot exceed available balance';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Please explain (min 3 chars)' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _ibanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IBAN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 8) ? 'Valid IBAN required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bankCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bank name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _countryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_submitting ? 'Submitting…' : 'Submit request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
