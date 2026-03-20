import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import 'models/checkout_review_model.dart';
import 'payment_webview_screen.dart';
import '../cart/providers/cart_providers.dart';
import '../orders/providers/orders_providers.dart';
import '../profile/providers/profile_providers.dart';
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
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
    final total = review != null ? (_tryParseMoney(review.total) ?? 0.0) : 0.0;
    final walletBalance = review != null
        ? (_tryParseMoney(review.walletBalance) ?? 0.0)
        : 0.0;
    final walletAppliedNow = review?.walletApplied != null
        ? (walletEnabled ? (review!.walletApplied ?? 0.0) : 0.0)
        : (walletEnabled
              ? (walletBalance > 0
                    ? (walletBalance > total ? total : walletBalance)
                    : 0.0)
              : 0.0);
    final amountDueNow = walletEnabled
        ? (review?.amountDueNow ??
              ((total - walletAppliedNow) > 0
                  ? (total - walletAppliedNow)
                  : 0.0))
        : total;

    // Guard against bypassing address requirement:
    // - must have a default shipping address (required for accurate shipping)
    final addressesAsync = ref.watch(addressesProvider);
    final defaultAddress = addressesAsync.valueOrNull
        ?.where((a) => a.isDefault)
        .firstOrNull;
    final hasDefaultAddress =
        defaultAddress != null && defaultAddress.addressLine.trim().isNotEmpty;

    return reviewAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Review & Pay')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
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
        if (!hasDefaultAddress) {
          return Scaffold(
            appBar: AppBar(title: const Text('Review & Pay')),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        AppConfig.radiusMedium,
                      ),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !hasDefaultAddress
                                    ? 'Add a default address to continue'
                                    : 'Add a default address to continue',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                !hasDefaultAddress
                                    ? 'Shipping depends on your default shipping address. Add an address and set it as default, then retry checkout.'
                                    : 'Shipping depends on your default shipping address. Add an address and set it as default, then retry checkout.',
                                style: AppTextStyles.bodySmall(
                                  AppConfig.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!hasDefaultAddress)
                    FilledButton(
                      onPressed: () => _openMyAddressesAndMaybeWarn(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Add / Set Default Address'),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(cartItemsProvider);
                      ref.invalidate(checkoutReviewProvider);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.textColor,
                      side: const BorderSide(color: AppConfig.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (r.shipments.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Review & Pay')),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: AppConfig.subtitleColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No approved items to checkout yet.'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Items pending review will stay in your cart until approved.',
                    style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go(AppRoutes.cart),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return _ReviewPayContent(
          review: r,
          walletEnabled: walletEnabled,
          amountDueNow: amountDueNow,
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
                  if (!hasDefaultAddress) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please add and set a default address to calculate shipping.',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _confirming = true);
                  final result = await confirmCheckout(
                    ref,
                    useWallet: walletEnabled,
                  );
                  if (!context.mounted) return;
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
                  if (!context.mounted) return;
                  setState(() => _confirming = false);
                  final checkoutUrl = paymentResult.checkoutUrl;
                  if (checkoutUrl != null && checkoutUrl.trim().isNotEmpty) {
                    final webViewResult = await context
                        .push<PaymentWebViewResult>(
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
                        const SnackBar(
                          content: Text(
                            'Payment page could not load. Please try again or use another device.',
                          ),
                        ),
                      );
                    } else if (webViewResult ==
                        PaymentWebViewResult.maybeCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment status updated.'),
                        ),
                      );
                    }
                  } else {
                    context.go('${AppRoutes.orderDetail}/$orderId');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          paymentResult.error ?? 'Could not start payment',
                        ),
                      ),
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
    final total = _tryParseMoney(review.total) ?? 0.0;
    final walletBalance = _tryParseMoney(review.walletBalance) ?? 0.0;
    final walletAppliedNow = walletEnabled
        ? (review.walletApplied ??
              (walletBalance > total ? total : walletBalance))
        : 0.0;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShippingCard(
                        address: review.shippingAddressShort,
                        onChangeTap: () =>
                            _openMyAddressesAndMaybeWarn(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ConsolidationBenefitCard(
                        savings: review.consolidationSavings,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...review.shipments.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _ShipmentSection(shipment: s),
                        ),
                      ),
                      _WalletBalanceRow(
                        balance: review.walletBalance,
                        enabled: walletEnabled,
                        onToggle: onWalletToggle,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _PriceDetailsSection(
                        review: review,
                        walletEnabled: walletEnabled,
                        walletAppliedNow: walletAppliedNow,
                        amountDueNow: amountDueNow,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PromoCodeField(
                        currentCode: review.promoCode,
                        promoMessage: review.promoMessage,
                        discountAmount: review.promoDiscountAmount,
                      ),
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
  const _ShippingCard({required this.address, required this.onChangeTap});

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
              TextButton(onPressed: onChangeTap, child: const Text('Change')),
            ],
          ),
          Text(address, style: AppTextStyles.bodyLarge(AppConfig.textColor)),
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
        border: Border.all(
          color: AppConfig.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: AppConfig.primaryColor, size: 24),
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
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        side: const BorderSide(color: AppConfig.borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          title: Text(
            shipment.originLabel,
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          subtitle: Text(
            '${shipment.items.length} item(s)',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          children: [
            for (final item in shipment.items) ...[
              _ShipmentItemRow(item: item),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
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
            child: () {
              final url = resolveAssetUrl(item.imageUrl, ApiClient.safeBaseUrl);
              if (url == null || url.isEmpty) {
                return const Icon(
                  Icons.image_outlined,
                  color: AppConfig.subtitleColor,
                  size: 28,
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.image_outlined,
                    color: AppConfig.subtitleColor,
                    size: 28,
                  ),
                ),
              );
            }(),
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
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppConfig.primaryColor,
            size: 24,
          ),
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
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _PriceDetailsSection extends StatelessWidget {
  const _PriceDetailsSection({
    required this.review,
    required this.walletEnabled,
    required this.walletAppliedNow,
    required this.amountDueNow,
  });

  final CheckoutReviewModel review;
  final bool walletEnabled;
  final double walletAppliedNow;
  final double amountDueNow;

  @override
  Widget build(BuildContext context) {
    final walletRowVisible = walletEnabled && walletAppliedNow > 0.0001;
    final promoVisible =
        (review.promoDiscountAmount ?? 0) > 0.0001 ||
        review.promoCode.trim().isNotEmpty;
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
          if (promoVisible)
            _PriceRow(
              label: review.promoCode.trim().isNotEmpty
                  ? 'Promo discount (${review.promoCode.trim()})'
                  : 'Promo discount',
              value:
                  '-\$${(review.promoDiscountAmount ?? 0).toStringAsFixed(2)}',
            ),
          if (walletRowVisible)
            _PriceRow(
              label: 'Wallet applied',
              value: '-\$${walletAppliedNow.toStringAsFixed(2)}',
            ),
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(
            label: 'Due now',
            value: '\$${amountDueNow.toStringAsFixed(2)}',
          ),
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
          Text(label, style: AppTextStyles.bodyMedium(AppConfig.subtitleColor)),
          Text(value, style: AppTextStyles.bodyMedium(AppConfig.textColor)),
        ],
      ),
    );
  }
}

class _PromoCodeField extends ConsumerStatefulWidget {
  const _PromoCodeField({
    required this.currentCode,
    required this.promoMessage,
    required this.discountAmount,
  });

  final String currentCode;
  final String promoMessage;
  final double? discountAmount;

  @override
  ConsumerState<_PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<_PromoCodeField> {
  late final TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCode);
  }

  @override
  void didUpdateWidget(covariant _PromoCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentCode != oldWidget.currentCode &&
        widget.currentCode != _controller.text) {
      _controller.text = widget.currentCode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate(BuildContext context, String code) async {
    final c = code.trim();
    if (c.isEmpty) {
      setState(() => _loading = false);
      ref.read(checkoutPromoCodeProvider.notifier).state = '';
      ref.invalidate(checkoutReviewProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promo code cleared')));
      return;
    }
    try {
      setState(() => _loading = true);
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/checkout/promo/validate',
        data: {'code': c},
      );
      if (!context.mounted) return;
      final data = res.data ?? const <String, dynamic>{};
      final valid = data['valid'] == true;
      final msg = (data['message'] ?? 'Done').toString();
      if (valid) {
        ref.read(checkoutPromoCodeProvider.notifier).state = c;
        ref.invalidate(checkoutReviewProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on DioException catch (e) {
      if (!context.mounted) return;
      final data = e.response?.data;
      final message = data is Map<String, dynamic>
          ? (data['message'] ?? 'Promo code is not valid').toString()
          : 'Promo code is not valid';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promo code is not valid')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.currentCode.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (applied && (widget.discountAmount ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'Applied ${widget.currentCode.trim()} - Discount \$${(widget.discountAmount ?? 0).toStringAsFixed(2)}',
              style: AppTextStyles.bodySmall(
                applied ? AppConfig.successGreen : AppConfig.subtitleColor,
              ),
            ),
          ),
        if (!applied && widget.promoMessage.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              widget.promoMessage,
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Promo Code',
                  suffixIcon: applied
                      ? const Icon(
                          Icons.local_offer_outlined,
                          color: AppConfig.successGreen,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
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
              onPressed: _loading
                  ? null
                  : () => _validate(context, _controller.text),
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
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Apply'),
            ),
            if (applied) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        ref.read(checkoutPromoCodeProvider.notifier).state = '';
                        ref.invalidate(checkoutReviewProvider);
                        _controller.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Promo code removed')),
                        );
                      },
                child: const Text('Remove'),
              ),
            ],
          ],
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
    final label = due <= 0
        ? 'Confirm Order'
        : 'Confirm & Pay ${_formatUsd(due)}';
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock, size: 20, color: Colors.white),
                label: Text(isLoading ? 'Processing...' : label),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
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
