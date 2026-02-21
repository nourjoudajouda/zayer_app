import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Top Up Wallet: balance card, amount presets + custom, payment method, order summary, confirm.
class TopUpWalletScreen extends StatefulWidget {
  const TopUpWalletScreen({super.key});

  @override
  State<TopUpWalletScreen> createState() => _TopUpWalletScreenState();
}

class _TopUpWalletScreenState extends State<TopUpWalletScreen> {
  static const double _mockBalance = 240.0;
  final List<double> _presets = [50, 100, 500];
  int _selectedPresetIndex = -1;
  final TextEditingController _customAmountController = TextEditingController();
  bool _useCustom = false;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = _selectedAmount;
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
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 40, color: AppConfig.primaryColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVAILABLE BALANCE',
                            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                          ),
                          Text(
                            '\$${_mockBalance.toStringAsFixed(2)}',
                            style: AppTextStyles.headlineSmall(AppConfig.textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select Top-up Amount',
                style: AppTextStyles.titleMedium(AppConfig.textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ..._presets.asMap().entries.map((e) {
                    final selected = !_useCustom && _selectedPresetIndex == e.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Material(
                        color: selected
                            ? AppConfig.primaryColor.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusSmall),
                        child: InkWell(
                          onTap: () => _selectPreset(e.key),
                          borderRadius:
                              BorderRadius.circular(AppConfig.radiusSmall),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? AppConfig.primaryColor
                                    : AppConfig.borderColor,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppConfig.radiusSmall),
                            ),
                            child: Text(
                              '\$${e.value.toStringAsFixed(0)}',
                              style: AppTextStyles.titleMedium(
                                  selected
                                      ? AppConfig.primaryColor
                                      : AppConfig.textColor),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _customAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onTap: () => setState(() {
                        _useCustom = true;
                        _selectedPresetIndex = -1;
                      }),
                      decoration: InputDecoration(
                        hintText: '\$0.00',
                        hintStyle:
                            AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConfig.radiusSmall),
                          borderSide:
                              const BorderSide(color: AppConfig.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Method',
                    style: AppTextStyles.titleMedium(AppConfig.textColor),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Change',
                      style: AppTextStyles.label(AppConfig.primaryColor),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: AppConfig.subtitleColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Visa ending in 4242',
                                style:
                                    AppTextStyles.titleMedium(AppConfig.textColor),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConfig.primaryColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DEFAULT',
                                  style: AppTextStyles.bodySmall(
                                      AppConfig.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Expires 12/26',
                            style:
                                AppTextStyles.bodySmall(AppConfig.subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: AppConfig.primaryColor, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Text(
                  'A small fee may apply depending on your payment method.',
                  style: AppTextStyles.bodySmall(Colors.orange.shade800),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 20),
                label: const Text('ADD NEW METHOD'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConfig.primaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'ORDER SUMMARY',
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        'Top-up Amount',
                        amount != null
                            ? '\$${amount.toStringAsFixed(2)}'
                            : '—'),
                    const _SummaryRow('Payment Method', 'Visa ****4242'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Protected by secure payment processing.',
                      style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: amount != null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Top up confirmed (mock)')),
                          );
                          context.pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                  child: const Text('Confirm Top Up'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  children: [
                    const TextSpan(text: 'By confirming, you agree to our '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: AppConfig.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium(AppConfig.subtitleColor)),
          Text(value, style: AppTextStyles.bodyMedium(AppConfig.textColor)),
        ],
      ),
    );
  }
}
