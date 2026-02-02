import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/checkout_review_model.dart';
import 'providers/checkout_review_providers.dart';

/// Review & Pay (consolidated checkout). Route: /review-pay.
/// API will plug in: GET /api/checkout/review, POST /api/checkout/confirm later.
class ReviewPayScreen extends ConsumerWidget {
  const ReviewPayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(checkoutReviewProvider);
    final walletEnabled = ref.watch(checkoutWalletEnabledProvider);

    return reviewAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Review & Pay')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (review) => _ReviewPayContent(
        review: review,
        walletEnabled: walletEnabled,
        onWalletToggle: (v) =>
            ref.read(checkoutWalletEnabledProvider.notifier).state = v,
      ),
    );
  }
}

class _ReviewPayContent extends StatelessWidget {
  const _ReviewPayContent({
    required this.review,
    required this.walletEnabled,
    required this.onWalletToggle,
  });

  final CheckoutReviewModel review;
  final bool walletEnabled;
  final ValueChanged<bool> onWalletToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Review & Pay'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShippingCard(
                      address: review.shippingAddressShort,
                      onChangeTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ConsolidationBenefitCard(
                      savings: review.consolidationSavings,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...review.shipments.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _ShipmentSection(shipment: s),
                        )),
                    _WalletBalanceRow(
                      balance: review.walletBalance,
                      enabled: walletEnabled,
                      onToggle: onWalletToggle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PriceDetailsSection(review: review),
                    const SizedBox(height: AppSpacing.md),
                    _PromoCodeField(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            _ConfirmPayBar(total: review.total),
          ],
        ),
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({
    required this.address,
    required this.onChangeTap,
  });

  final String address;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping to',
                style: AppTextStyles.label(AppConfig.subtitleColor),
              ),
              TextButton(
                onPressed: onChangeTap,
                child: const Text('Change'),
              ),
            ],
          ),
          Text(
            address,
            style: AppTextStyles.bodyLarge(AppConfig.textColor),
          ),
        ],
      ),
    );
  }
}

class _ConsolidationBenefitCard extends StatelessWidget {
  const _ConsolidationBenefitCard({required this.savings});

  final String savings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings_outlined,
            color: AppConfig.primaryColor,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'You saved $savings with consolidation.',
              style: AppTextStyles.bodyMedium(AppConfig.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentSection extends StatelessWidget {
  const _ShipmentSection({required this.shipment});

  final CheckoutShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            shipment.originLabel,
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...shipment.items.map((item) => _ShipmentItemRow(
                item: item,
                showReviewed: shipment.reviewed,
              )),
        ],
      ),
    );
  }
}

class _ShipmentItemRow extends StatelessWidget {
  const _ShipmentItemRow({
    required this.item,
    this.showReviewed = true,
  });

  final CheckoutShipmentItem item;
  final bool showReviewed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppConfig.lightBlueBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: Icon(
              Icons.image_outlined,
              color: AppConfig.subtitleColor,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium(AppConfig.textColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (showReviewed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppConfig.successGreen.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                    child: Text(
                      'REVIEWED',
                      style: AppTextStyles.bodySmall(AppConfig.successGreen),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
Text(
                  item.price,
                  style: AppTextStyles.titleMedium(AppConfig.textColor),
                ),
                    const SizedBox(width: AppSpacing.md),
                    _Stepper(
                      value: item.quantity,
                      onMinus: () {},
                      onPlus: () {},
                    ),
                  ],
                ),
                Text(
                  'ETA: ${item.eta}',
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 22),
          onPressed: onMinus,
          color: AppConfig.primaryColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '$value',
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          onPressed: onPlus,
          color: AppConfig.primaryColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _WalletBalanceRow extends StatelessWidget {
  const _WalletBalanceRow({
    required this.balance,
    required this.enabled,
    required this.onToggle,
  });

  final String balance;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: AppConfig.primaryColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet balance',
                  style: AppTextStyles.label(AppConfig.subtitleColor),
                ),
                Text(
                  balance,
                  style: AppTextStyles.titleMedium(AppConfig.textColor),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _PriceDetailsSection extends StatelessWidget {
  const _PriceDetailsSection({required this.review});

  final CheckoutReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Price Details',
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(label: 'Subtotal', value: review.subtotal),
          _PriceRow(label: 'Shipping', value: review.shipping),
          _PriceRow(label: 'Insurance', value: review.insurance),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium(AppConfig.textColor),
          ),
        ],
      ),
    );
  }
}

class _PromoCodeField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Promo Code',
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConfig.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ConfirmPayBar extends StatelessWidget {
  const _ConfirmPayBar({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        border: Border(top: BorderSide(color: AppConfig.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.lock, size: 20, color: Colors.white),
                label: Text('Confirm & Pay $total'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConfig.radiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Secure payment',
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
