import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/shipping_estimate_disclosure.dart';
import '../../generated/l10n/app_localizations.dart';
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
  void dispose() {
    // Cart sets proceedingToCheckout while awaiting push; if navigation uses
    // go/replace, the awaiting callback can fail to clear the flag — always reset here.
    try {
      ref.read(proceedingToCheckoutProvider.notifier).state = false;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CheckoutReviewModel>>(checkoutReviewProvider, (prev, next) {
      ref.read(checkoutPaymentMethodSelectionProvider.notifier).state = null;
    });
    final reviewAsync = ref.watch(checkoutReviewProvider);
    final review = reviewAsync.valueOrNull;
    final methodOverride = ref.watch(checkoutPaymentMethodSelectionProvider);
    final payable = review != null
        ? (review.payableNowTotal ?? _tryParseMoney(review.total) ?? 0.0)
        : 0.0;
    final walletBalance =
        review != null ? (_tryParseMoney(review.walletBalance) ?? 0.0) : 0.0;
    final method =
        review != null ? _effectivePaymentMethod(review, methodOverride) : 'gateway';
    final canWalletPay = review != null
        ? _canPayWithWallet(review, walletBalance, payable)
        : false;
    double walletAppliedNow;
    double amountDueNow;
    if (review != null && method == 'wallet' && canWalletPay) {
      walletAppliedNow = payable;
      amountDueNow = 0.0;
    } else {
      walletAppliedNow = 0.0;
      amountDueNow = payable;
    }
    final canConfirm =
        review != null ? _canPlaceOrder(review, method, canWalletPay) : false;

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
          paymentMethod: method,
          payableNow: payable,
          walletBalanceAmount: walletBalance,
          canWalletPay: canWalletPay,
          walletAppliedNow: walletAppliedNow,
          amountDueNow: amountDueNow,
          confirming: _confirming,
          onRefresh: () async {
            ref.invalidate(checkoutReviewProvider);
            await ref.read(checkoutReviewProvider.future);
          },
          onSelectPaymentMethod: (m) => ref
              .read(checkoutPaymentMethodSelectionProvider.notifier)
              .state = m,
          onTopUpWallet: (shortage) async {
            await context.push<double?>(
              AppRoutes.topUpWallet,
              extra: shortage,
            );
            if (context.mounted) {
              ref.invalidate(checkoutReviewProvider);
              ref.invalidate(walletBalanceProvider);
            }
          },
          onConfirm: _confirming || !canConfirm
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
                    paymentMethod: method,
                  );
                  if (!context.mounted) return;
                  if (!result.ok) {
                    setState(() => _confirming = false);
                    final code = result.errorCode;
                    if (code == 'insufficient_wallet_balance') {
                      final msg = result.message ??
                          'Please top up your wallet to cover this order.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.message ?? 'Checkout failed',
                          ),
                        ),
                      );
                    }
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
                    ref.invalidate(cartItemsProvider);
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

String _effectivePaymentMethod(CheckoutReviewModel r, String? override) {
  if (override == 'wallet' || override == 'gateway') {
    return override!;
  }
  switch (r.checkoutPaymentMode) {
    case 'wallet_only':
      return 'wallet';
    default:
      return 'gateway';
  }
}

bool _canPayWithWallet(CheckoutReviewModel r, double balance, double payable) {
  if (payable <= 0.0001) return true;
  return r.walletCanPayNow || balance + 0.0001 >= payable;
}

bool _canPlaceOrder(
  CheckoutReviewModel r,
  String method,
  bool canWalletPay,
) {
  if (method == 'wallet' && !canWalletPay) return false;
  return true;
}

/// Derive "5%" style label for service fee line when API does not send percent.
String _checkoutFeePercentLabel(CheckoutReviewModel review) {
  final sub = _tryParseMoney(review.subtotal) ?? 0;
  final fee = review.appFeeAmount ?? 0;
  if (sub <= 0 || fee <= 0) return '0%';
  final pct = (fee / sub) * 100.0;
  return pct == pct.roundToDouble() ? '${pct.round()}%' : '${pct.toStringAsFixed(2)}%';
}

/// Split order-level app fee across lines by [CheckoutShipmentItem.lineSubtotal] when API omits per-line fee.
Map<String, double> _perItemAppFeeAllocated(CheckoutReviewModel review) {
  final total = review.appFeeAmount ?? 0;
  if (total <= 0) return {};
  var sum = 0.0;
  for (final s in review.shipments) {
    for (final it in s.items) {
      sum += it.lineSubtotal ?? 0;
    }
  }
  if (sum <= 0) return {};
  final map = <String, double>{};
  for (final s in review.shipments) {
    for (final it in s.items) {
      final id = it.id;
      if (id.isEmpty) continue;
      final sub = it.lineSubtotal ?? 0;
      map[id] = double.parse((total * sub / sum).toStringAsFixed(2));
    }
  }
  return map;
}

double? _globalAppFeePercentForShipmentItems(CheckoutReviewModel review) {
  final sub = _tryParseMoney(review.subtotal);
  final fee = review.appFeeAmount;
  if (sub == null || sub <= 0 || fee == null || fee <= 0) return null;
  final pct = (fee / sub) * 100.0;
  return pct;
}

String _shipmentItemShippingValueText(CheckoutShipmentItem item) {
  if (item.shippingAmount != null) {
    return '≈ \$${item.shippingAmount!.toStringAsFixed(2)}';
  }
  final c = item.shippingCost?.trim();
  if (c != null && c.isNotEmpty) return c;
  return '—';
}

String _shipmentItemServiceFeeLabel(
  AppLocalizations? l10n,
  CheckoutShipmentItem item,
  double? orderLevelPercent,
) {
  final p = item.appFeePercent ?? orderLevelPercent;
  if (p != null && p > 0) {
    final s = p == p.roundToDouble() ? '${p.round()}%' : '${p.toStringAsFixed(2)}%';
    return l10n?.serviceFeePercentLine(s) ?? 'Service Fee ($s)';
  }
  return 'Service fee';
}

double? _resolvedLineAppFee(
  CheckoutShipmentItem item,
  Map<String, double> allocated,
  CheckoutReviewModel review,
) {
  if (item.appFeeAmount != null) return item.appFeeAmount;
  if (item.id.isNotEmpty && allocated.containsKey(item.id)) {
    return allocated[item.id];
  }
  var count = 0;
  for (final s in review.shipments) {
    count += s.items.length;
  }
  if (count == 1) return review.appFeeAmount;
  return null;
}

String _formatUsd(double v) => '\$${v.toStringAsFixed(2)}';

class _ReviewPayContent extends StatelessWidget {
  const _ReviewPayContent({
    required this.review,
    required this.paymentMethod,
    required this.payableNow,
    required this.walletBalanceAmount,
    required this.canWalletPay,
    required this.walletAppliedNow,
    required this.amountDueNow,
    required this.confirming,
    required this.onSelectPaymentMethod,
    required this.onTopUpWallet,
    this.onConfirm,
    this.onRefresh,
  });

  final CheckoutReviewModel review;
  final String paymentMethod;
  final double payableNow;
  final double walletBalanceAmount;
  final bool canWalletPay;
  final double walletAppliedNow;
  final double amountDueNow;
  final bool confirming;
  final ValueChanged<String> onSelectPaymentMethod;
  final Future<void> Function(double shortage) onTopUpWallet;
  final VoidCallback? onConfirm;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final allocated = _perItemAppFeeAllocated(review);
    final orderPct = _globalAppFeePercentForShipmentItems(review);
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
                          child: _ShipmentSection(
                            shipment: s,
                            review: review,
                            allocated: allocated,
                            orderPct: orderPct,
                          ),
                        ),
                      ),
                      _CheckoutPaymentSection(
                        review: review,
                        paymentMethod: paymentMethod,
                        payableNow: payableNow,
                        walletBalanceAmount: walletBalanceAmount,
                        canWalletPay: canWalletPay,
                        onSelectPaymentMethod: onSelectPaymentMethod,
                        onTopUpWallet: onTopUpWallet,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _PriceDetailsSection(
                        review: review,
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
  const _ShipmentSection({
    required this.shipment,
    required this.review,
    required this.allocated,
    required this.orderPct,
  });

  final CheckoutShipment shipment;
  final CheckoutReviewModel review;
  final Map<String, double> allocated;
  final double? orderPct;

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
              _ShipmentItemRow(
                item: item,
                review: review,
                allocated: allocated,
                orderPct: orderPct,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShipmentItemRow extends StatelessWidget {
  const _ShipmentItemRow({
    required this.item,
    required this.review,
    required this.allocated,
    required this.orderPct,
  });

  final CheckoutShipmentItem item;
  final CheckoutReviewModel review;
  final Map<String, double> allocated;
  final double? orderPct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lineFee = _resolvedLineAppFee(item, allocated, review);
    final feeLabel = _shipmentItemServiceFeeLabel(l10n, item, orderPct);
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
                const SizedBox(height: AppSpacing.xs),
                ShippingEstimateReferenceRow(
                  dense: true,
                  valueText: _shipmentItemShippingValueText(item),
                ),
                if (lineFee != null && lineFee > 0.0001) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          feeLabel,
                          style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                        ),
                      ),
                      Text(
                        _formatUsd(lineFee),
                        style: AppTextStyles.bodySmall(AppConfig.textColor),
                      ),
                    ],
                  ),
                ],
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

class _CheckoutPaymentSection extends StatelessWidget {
  const _CheckoutPaymentSection({
    required this.review,
    required this.paymentMethod,
    required this.payableNow,
    required this.walletBalanceAmount,
    required this.canWalletPay,
    required this.onSelectPaymentMethod,
    required this.onTopUpWallet,
  });

  final CheckoutReviewModel review;
  final String paymentMethod;
  final double payableNow;
  final double walletBalanceAmount;
  final bool canWalletPay;
  final ValueChanged<String> onSelectPaymentMethod;
  final Future<void> Function(double shortage) onTopUpWallet;

  @override
  Widget build(BuildContext context) {
    final mode = review.checkoutPaymentMode;
    final showWallet = review.walletEnabledForCheckout;
    final showGateway = review.gatewayEnabledForCheckout;
    final shortage = (payableNow - walletBalanceAmount) > 0
        ? (payableNow - walletBalanceAmount)
        : 0.0;

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
            'Payment',
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showWallet) ...[
            _paymentRow(
              title: 'Wallet balance',
              value: '\$${walletBalanceAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _paymentRow(
              title: 'Total to pay now',
              value: '\$${payableNow.toStringAsFixed(2)}',
            ),
            if (paymentMethod == 'wallet' && !canWalletPay) ...[
              const SizedBox(height: AppSpacing.xs),
              _paymentRow(
                title: 'Need to top up',
                value: '\$${shortage.toStringAsFixed(2)}',
                emphasize: true,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
          if (showWallet && showGateway) ...[
            Text(
              'Choose how to pay',
              style: AppTextStyles.label(AppConfig.subtitleColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            _methodTile(
              context,
              selected: paymentMethod == 'wallet',
              title: 'Wallet',
              subtitle: canWalletPay
                  ? 'Pay using your balance'
                  : 'Insufficient balance',
              enabled: true,
              onTap: () => onSelectPaymentMethod('wallet'),
            ),
            _methodTile(
              context,
              selected: paymentMethod == 'gateway',
              title: 'Card / payment gateway',
              subtitle: 'Secure checkout',
              enabled: true,
              onTap: () => onSelectPaymentMethod('gateway'),
            ),
          ] else if (showWallet && !showGateway) ...[
            Text(
              'This checkout is configured for wallet payment only.',
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          ] else if (!showWallet && showGateway) ...[
            Text(
              'Pay securely with your card on the next step.',
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          ],
          if (showWallet &&
              paymentMethod == 'wallet' &&
              !canWalletPay &&
              mode != 'gateway_only') ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: shortage > 0 ? () => onTopUpWallet(shortage) : null,
                icon: const Icon(Icons.add_card_outlined, size: 20),
                label: const Text('Top Up Wallet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.primaryColor,
                  side: BorderSide(color: AppConfig.primaryColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentRow({
    required String title,
    required String value,
    bool emphasize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
        ),
        Text(
          value,
          style: emphasize
              ? AppTextStyles.titleMedium(AppConfig.errorRed)
              : AppTextStyles.bodyMedium(AppConfig.textColor),
        ),
      ],
    );
  }

  Widget _methodTile(
    BuildContext context, {
    required bool selected,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected
            ? AppConfig.primaryColor.withValues(alpha: 0.12)
            : AppConfig.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppConfig.primaryColor : AppConfig.subtitleColor,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium(AppConfig.textColor),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceDetailsSection extends StatelessWidget {
  const _PriceDetailsSection({
    required this.review,
    required this.walletAppliedNow,
    required this.amountDueNow,
  });

  final CheckoutReviewModel review;
  final double walletAppliedNow;
  final double amountDueNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final walletRowVisible = walletAppliedNow > 0.0001;
    final promoVisible =
        (review.promoDiscountAmount ?? 0) > 0.0001 ||
        review.promoCode.trim().isNotEmpty;
    final feeAmt = review.appFeeAmount ?? 0.0;
    final showServiceFee = feeAmt > 0.0001;
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Shipping will be calculated after items arrive at the warehouse (separate payment).',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(label: 'Subtotal', value: review.subtotal),
          if (showServiceFee)
            _PriceRow(
              label: l10n?.serviceFeePercentLine(
                    _checkoutFeePercentLabel(review),
                  ) ??
                  'Service fee',
              value: review.serviceFee.trim().isNotEmpty
                  ? review.serviceFee
                  : '\$${feeAmt.toStringAsFixed(2)}',
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShippingEstimateReferenceRow(
                dense: true,
                valueText: review.shipping.trim().isNotEmpty
                    ? review.shipping
                    : (review.shippingEstimateAmount != null
                        ? '\$${review.shippingEstimateAmount!.toStringAsFixed(2)}'
                        : '—'),
              ),
              ShippingEstimateFootnote(dense: true),
            ],
          ),
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
            label: l10n?.totalToPayNowLabel ?? 'Order total',
            value: review.total,
          ),
          const SizedBox(height: AppSpacing.xs),
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
