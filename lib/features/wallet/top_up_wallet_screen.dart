import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../checkout/payment_webview_screen.dart';
import 'models/wallet_model.dart';
import 'providers/wallet_providers.dart';

/// Top Up Wallet: available balance, amount presets + custom, payment method, order summary, confirm.
class TopUpWalletScreen extends ConsumerStatefulWidget {
  const TopUpWalletScreen({super.key});

  @override
  ConsumerState<TopUpWalletScreen> createState() => _TopUpWalletScreenState();
}

class _TopUpWalletScreenState extends ConsumerState<TopUpWalletScreen> {
  final List<double> _presets = [50, 100, 500];
  int _selectedPresetIndex = 1;
  final TextEditingController _customAmountController = TextEditingController(text: '100.00');
  bool _useCustom = false;
  bool _isConfirming = false;
  bool _savePaymentMethod = false;

  @override
  void initState() {
    super.initState();
    _customAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double? get _selectedAmount {
    if (_useCustom) {
      final v = double.tryParse(_customAmountController.text.trim());
      return v != null && v > 0 ? v : null;
    }
    if (_selectedPresetIndex >= 0 && _selectedPresetIndex < _presets.length) {
      return _presets[_selectedPresetIndex];
    }
    return null;
  }

  void _selectPreset(int i) {
    setState(() {
      _selectedPresetIndex = i;
      _useCustom = false;
      _customAmountController.text = _presets[i].toStringAsFixed(2);
    });
  }

  Future<void> _confirmTopUp() async {
    final amount = _selectedAmount;
    if (amount == null || amount <= 0) return;
    setState(() => _isConfirming = true);
    try {
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/top-up',
        data: {
          'amount': amount,
          // Best-effort: only meaningful if backend supports saving a method.
          'save_payment_method': _savePaymentMethod,
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final topUp = data['top_up'] is Map<String, dynamic>
          ? data['top_up'] as Map<String, dynamic>
          : (data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : null);
      final checkoutUrl = (topUp?['checkout_url'] ?? data['checkout_url'])
          ?.toString()
          .trim();

      // If backend provides a real payment URL, launch hosted checkout flow.
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final result = await context.push<PaymentWebViewResult>(
          AppRoutes.paymentWebView,
          extra: checkoutUrl,
        );
        if (!mounted) return;
        ref.invalidate(walletBalanceProvider);
        ref.invalidate(walletTransactionsProvider);
        if (result == PaymentWebViewResult.failedToLoad) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment page could not load. Please try again or use another device.')),
          );
          return;
        }
        // On close/maybeCompleted, refresh wallet and leave the screen.
        await ref.read(walletBalanceProvider.future);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet updated.')),
        );
        context.pop();
        return;
      }

      // No checkout URL returned: do not pretend the top-up completed.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Top-up payment is not available right now. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Top-up failed. Please try again or use another payment method.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final balance = balanceAsync.valueOrNull ?? const WalletBalance(available: 0, pending: 0, promo: 0);
    final amount = _selectedAmount;
    final defaultGateway = ref.watch(bootstrapConfigProvider).valueOrNull?.paymentGateways?.defaultGatewayCode;
    final gatewayLabel = (defaultGateway == 'stripe') ? 'Stripe' : 'Square';

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AVAILABLE BALANCE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${balance.available.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.account_balance_wallet_outlined, size: 32, color: AppConfig.primaryColor.withValues(alpha: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select Top-up Amount', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = 0; i < _presets.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PresetButton(
                        amount: _presets[i],
                        isSelected: !_useCustom && _selectedPresetIndex == i,
                        onTap: () => _selectPreset(i),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onTap: () => setState(() {
                  _useCustom = true;
                  _selectedPresetIndex = -1;
                }),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: AppConfig.primaryColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay securely with $gatewayLabel',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You’ll enter your card details on the secure checkout page after you confirm.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _savePaymentMethod,
                onChanged: (v) => setState(() => _savePaymentMethod = v),
                title: const Text('Save payment method for next time'),
                subtitle: Text(
                  'Only applies if supported by checkout.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppConfig.primaryColor,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('ORDER SUMMARY', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.subtitleColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Column(
                  children: [
                    _SummaryRow('Top-up Amount', amount != null ? '\$${amount.toStringAsFixed(2)}' : '—'),
                    _SummaryRow('Payment', 'Secure checkout ($gatewayLabel)'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: AppConfig.successGreen),
                        const SizedBox(width: 6),
                        Text('Protected by secure payment processing', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: (amount != null && !_isConfirming) ? _confirmTopUp : null,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.lock_outline, size: 20),
                  label: Text(_isConfirming ? 'Processing...' : 'Confirm Top Up'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                  children: [
                    const TextSpan(text: 'By clicking \'Confirm\', you authorize Zayer to charge your payment method. '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          'View our Terms of Service.',
                          style: TextStyle(color: AppConfig.primaryColor, decoration: TextDecoration.underline, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.amount, required this.isSelected, required this.onTap});

  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppConfig.primaryColor : AppConfig.borderColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            border: Border.all(color: isSelected ? AppConfig.primaryColor : AppConfig.borderColor),
          ),
          child: Center(
            child: Text(
              '\$${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppConfig.textColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
