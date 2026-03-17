import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/checkout_review_model.dart';
import 'payment_webview_screen.dart';
import '../cart/providers/cart_providers.dart';
import '../orders/providers/orders_providers.dart';
import '../wallet/providers/wallet_providers.dart';
import 'providers/checkout_review_providers.dart';

/// Opens My Addresses first. When user returns after saving/editing address, shows recalculation warning.
void _openMyAddressesAndMaybeWarn(BuildContext context) async {
  final addressChanged = await context.push<bool>(AppRoutes.myAddresses);
  if (context.mounted && addressChanged == true) {
    _showRecalculationWarning(context);
  }
}

/// Shows the "Change Address? Recalculate" warning (only after user actually changed address).
void _showRecalculationWarning(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(ctx).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppConfig.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.location_off_rounded,
              size: 48,
              color: AppConfig.errorRed,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Change Address?',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Shipping costs were calculated based on your previous address. '
              'Your new address will recalculate all prices, taxes, and delivery estimates for your order.',
              style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Recalculate'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.textColor,
                  side: const BorderSide(color: AppConfig.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Keep Current Calculation'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Review & Pay (consolidated checkout). Route: /review-pay.
/// API: GET /api/checkout/review, POST /api/checkout/confirm.
class ReviewPayScreen extends ConsumerStatefulWidget {
  const ReviewPayScreen({super.key});

  @override
  ConsumerState<ReviewPayScreen> createState() => _ReviewPayScreenState();
}

class _ReviewPayScreenState extends ConsumerState<ReviewPayScreen> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(checkoutReviewProvider);
    final review = reviewAsync.valueOrNull;
    final walletEnabled = ref.watch(checkoutWalletEnabledProvider);
    final amountDueNow = review != null
        ? (review.amountDueNow ?? _tryParseMoney(review.total) ?? 0)
        : 0.0;

    return reviewAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Review & Pay')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Review & Pay')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Couldn\'t load checkout.'),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(checkoutReviewProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (r) {
        if (r.shipments.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Review & Pay')),
            body: const Center(
              child: Text('Your cart is empty. Add items from the cart.'),
            ),
          );
        }
        return _ReviewPayContent(
          review: r,
          walletEnabled: walletEnabled,
          amountDueNow: r.amountDueNow ?? _tryParseMoney(r.total) ?? 0,
          confirming: _confirming,
          onRefresh: () async {
            ref.invalidate(checkoutReviewProvider);
            await ref.read(checkoutReviewProvider.future);
          },
          onWalletToggle: (v) =>
              ref.read(checkoutWalletEnabledProvider.notifier).state = v,
          onConfirm: _confirming
              ? null
              : () async {
                  setState(() => _confirming = true);
                  final result = await confirmCheckout(ref, useWallet: walletEnabled);
                  if (!mounted) return;
                  if (!result.ok) {
                    setState(() => _confirming = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkout failed')),
                    );
                    return;
                  }
                  ref.invalidate(cartItemsProvider);
                  ref.invalidate(ordersProvider);
                  ref.invalidate(walletBalanceProvider);
                  ref.invalidate(walletTransactionsProvider);
                  final orderId = result.orderId;
                  if (orderId == null || orderId.isEmpty) {
                    setState(() => _confirming = false);
                    context.go(AppRoutes.orders);
                    return;
                  }
                  final dueNow = amountDueNow;
                  if (dueNow <= 0) {
                    setState(() => _confirming = false);
                    context.go('${AppRoutes.orderDetail}/$orderId');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order confirmed.')),
                    );
                    return;
                  }

                  final paymentResult = await startOrderPayment(orderId);
                  if (!mounted) return;
                  setState(() => _confirming = false);
                  final checkoutUrl = paymentResult.checkoutUrl;
                  if (checkoutUrl != null && checkoutUrl.trim().isNotEmpty) {
                    final webViewResult = await context.push<PaymentWebViewResult>(
                      AppRoutes.paymentWebView,
                      extra: checkoutUrl,
                    );
                    if (!context.mounted) return;
                    context.go('${AppRoutes.orderDetail}/$orderId');
                    ref.invalidate(orderByIdProvider(orderId));
                    ref.invalidate(ordersProvider);
                    ref.invalidate(checkoutReviewProvider);
                    try {
                      await ref.read(orderByIdProvider(orderId).future);
                    } catch (_) {
                      // Network or API failure while refreshing; do not crash
                    }
                    if (!context.mounted) return;
                    if (webViewResult == PaymentWebViewResult.failedToLoad) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment page could not load. Please try again or use another device.')),
                      );
                    } else if (webViewResult == PaymentWebViewResult.maybeCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment status updated.')),
                      );
                    }
                  } else {
                    context.go('${AppRoutes.orderDetail}/$orderId');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(paymentResult.error ?? 'Could not start payment')),
                    );
                  }
                },
        );
      },
    );
  }
}

double? _tryParseMoney(String v) {
  final cleaned = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  return double.tryParse(cleaned);
}

class _ReviewPayContent extends StatelessWidget {
  const _ReviewPayContent({
    required this.review,
    required this.walletEnabled,
    required this.amountDueNow,
    required this.confirming,
    required this.onWalletToggle,
    this.onConfirm,
    this.onRefresh,
  });

  final CheckoutReviewModel review;
  final bool walletEnabled;
  final double amountDueNow;
  final bool confirming;
  final ValueChanged<bool> onWalletToggle;
  final VoidCallback? onConfirm;
  final Future<void> Function()? onRefresh;

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
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShippingCard(
                      address: review.shippingAddressShort,
                      onChangeTap: () => _openMyAddressesAndMaybeWarn(context),
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
            ),
                    _ConfirmPayBar(
                      amountDueNow: amountDueNow,
                      onConfirm: onConfirm,
                      isLoading: confirming,
                    ),
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
          ...shipment.items.map((item) => _ShipmentItemRow(item: item)),
        ],
      ),
    );
  }
}

class _ShipmentItemRow extends StatelessWidget {
  const _ShipmentItemRow({required this.item});

  final CheckoutShipmentItem item;

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (item.reviewed
                            ? AppConfig.successGreen
                            : Colors.orange)
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: Text(
                    item.reviewed ? 'REVIEWED' : 'PENDING REVIEW',
                    style: AppTextStyles.bodySmall(
                      item.reviewed ? AppConfig.successGreen : Colors.orange.shade800,
                    ),
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
                if (item.shippingCost != null && item.shippingCost!.isNotEmpty)
                  Text(
                    'Shipping: ${item.shippingCost}',
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
  const _ConfirmPayBar({
    required this.amountDueNow,
    this.onConfirm,
    this.isLoading = false,
  });

  final double amountDueNow;
  final VoidCallback? onConfirm;
  final bool isLoading;

  static String _formatUsd(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final due = amountDueNow;
    final label = due <= 0 ? 'Confirm Order' : 'Confirm & Pay ${_formatUsd(due)}';
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
                onPressed: isLoading ? null : onConfirm,
                icon: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock, size: 20, color: Colors.white),
                label: Text(isLoading ? 'Processing...' : label),
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
