/// Review & Pay (checkout) model. API: GET /api/checkout/review, POST confirm later.
class CheckoutShipmentItem {
  const CheckoutShipmentItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.eta,
    this.imageUrl,
    this.shippingCost,
    this.id = '',
    this.lineSubtotal,
    this.shippingAmount,
    this.appFeeAmount,
    this.appFeePercent,
  });

  final String name;
  /// Formatted unit price from API (`price`).
  final String price;
  final int quantity;
  final String eta;
  final String? imageUrl;
  /// Formatted shipping for the line (`shipping_cost`), when present.
  final String? shippingCost;

  /// Cart line id (for allocating summary-level fees per item).
  final String id;
  /// Numeric line subtotal from API (`subtotal`).
  final double? lineSubtotal;
  /// Numeric shipping estimate for the line (`shipping_amount`).
  final double? shippingAmount;
  /// When API sends per-line fee (`app_fee_amount`).
  final double? appFeeAmount;
  /// When API sends per-line percent (`app_fee_percent`).
  final double? appFeePercent;
}

class CheckoutShipment {
  const CheckoutShipment({
    required this.originLabel,
    required this.items,
  });

  final String originLabel;
  final List<CheckoutShipmentItem> items;
}

class CheckoutReviewModel {
  const CheckoutReviewModel({
    this.shippingAddressShort = '',
    this.consolidationSavings = '',
    this.walletBalanceEnabled = true,
    this.checkoutPaymentMode = 'gateway_only',
    this.walletEnabledForCheckout = true,
    this.gatewayEnabledForCheckout = true,
    this.allowedPaymentMethods = const ['wallet', 'gateway'],
    this.walletBalance = '',
    this.subtotal = '',
    this.serviceFee = '',
    this.shipping = '',
    this.insurance = '',
    this.total = '',
    this.amountDueNow,
    this.walletApplied,
    this.appFeeAmount,
    this.payableNowTotal,
    this.shippingEstimateAmount,
    this.shippingPayableNow = 0,
    this.walletShortfall,
    this.walletCanPayNow = false,
    this.topUpRequired = false,
    this.requiredTopUpAmount,
    this.suggestedTopUpAmount,
    this.promoCode = '',
    this.promoValid = false,
    this.promoMessage = '',
    this.promoDiscountAmount,
    this.priceLines = const [],
    required this.shipments,
  });

  final String shippingAddressShort;
  final String consolidationSavings;
  final bool walletBalanceEnabled;
  /// Admin setting: `wallet_only` | `gateway_only` | `wallet_and_gateway`.
  final String checkoutPaymentMode;
  final bool walletEnabledForCheckout;
  final bool gatewayEnabledForCheckout;
  final List<String> allowedPaymentMethods;
  final String walletBalance;
  final String subtotal;
  /// Formatted service fee (product + fee flow).
  final String serviceFee;
  final String shipping;
  final String insurance;
  final String total;
  /// Amount due now after wallet application (backend source of truth).
  final double? amountDueNow;
  /// Wallet amount applied (if provided by backend).
  final double? walletApplied;
  final double? appFeeAmount;
  final double? payableNowTotal;
  final double? shippingEstimateAmount;
  final int shippingPayableNow;
  final double? walletShortfall;
  final bool walletCanPayNow;
  final bool topUpRequired;
  final double? requiredTopUpAmount;
  final double? suggestedTopUpAmount;
  final String promoCode;
  final bool promoValid;
  final String promoMessage;
  final double? promoDiscountAmount;
  final List<Map<String, dynamic>> priceLines;
  final List<CheckoutShipment> shipments;

  factory CheckoutReviewModel.fromJson(Map<String, dynamic> j) {
    final shipmentsList = j['shipments'] as List<dynamic>?;
    final shipments = shipmentsList?.map((s) {
      final sm = s as Map<String, dynamic>;
      final itemsList = sm['items'] as List<dynamic>?;
      final items = itemsList?.map((i) {
        final im = i as Map<String, dynamic>;
        return CheckoutShipmentItem(
          name: (im['name'] ?? '').toString(),
          price: (im['price'] ?? '\$0.00').toString(),
          quantity: (im['quantity'] as int?) ?? 1,
          eta: (im['eta'] ?? '').toString(),
          imageUrl: im['image_url'] as String?,
          shippingCost: im['shipping_cost'] as String?,
          id: (im['id'] ?? '').toString(),
          lineSubtotal: (im['subtotal'] as num?)?.toDouble(),
          shippingAmount: (im['shipping_amount'] as num?)?.toDouble(),
          appFeeAmount: (im['app_fee_amount'] as num?)?.toDouble(),
          appFeePercent: (im['app_fee_percent'] as num?)?.toDouble(),
        );
      }).toList() ?? [];
      return CheckoutShipment(
        originLabel: (sm['origin_label'] ?? '').toString(),
        items: items,
      );
    }).toList() ?? [];
    final pricing = j['pricing'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(j['pricing'] as Map)
        : null;
    final mode =
        (j['checkout_payment_mode'] ?? pricing?['checkout_payment_mode'] ?? 'gateway_only')
            .toString();
    final allowedRaw = j['allowed_payment_methods'] ?? pricing?['allowed_payment_methods'];
    final allowed = allowedRaw is List
        ? allowedRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return CheckoutReviewModel(
      shippingAddressShort: (j['shipping_address_short'] ?? '').toString(),
      consolidationSavings: (j['consolidation_savings'] ?? '\$0.00').toString(),
      walletBalanceEnabled: j['wallet_enabled_for_checkout'] == true ||
          j['wallet_balance_enabled'] == true ||
          (j['wallet_enabled_for_checkout'] == null &&
              j['wallet_balance_enabled'] != false),
      checkoutPaymentMode: mode,
      walletEnabledForCheckout: j['wallet_enabled_for_checkout'] == true ||
          (j['wallet_enabled_for_checkout'] == null &&
              j['wallet_balance_enabled'] != false),
      gatewayEnabledForCheckout: j['gateway_enabled_for_checkout'] != false,
      allowedPaymentMethods: allowed.isNotEmpty
          ? allowed
          : _defaultAllowedMethods(mode),
      walletBalance: (j['wallet_balance'] ?? '\$0.00').toString(),
      subtotal: (j['subtotal'] ?? '\$0.00').toString(),
      serviceFee: (j['service_fee'] ?? '\$0.00').toString(),
      shipping: (j['shipping'] ?? '\$0.00').toString(),
      insurance: (j['insurance'] ?? '\$0.00').toString(),
      total: (j['total'] ?? '\$0.00').toString(),
      amountDueNow: _parseMoney(j['amount_due_now'] ?? j['due_now'] ?? j['amount_due'] ?? pricing?['amount_due_now']),
      walletApplied: _parseMoney(j['wallet_applied'] ?? j['wallet_applied_amount'] ?? pricing?['wallet_applied_amount']),
      appFeeAmount: _parseMoney(pricing?['app_fee_amount'] ?? pricing?['app_fee_total']),
      payableNowTotal: _parseMoney(pricing?['payable_now_total']),
      shippingEstimateAmount: _parseMoney(pricing?['shipping_estimate_amount'] ?? pricing?['shipping']),
      shippingPayableNow: (pricing?['shipping_payable_now'] as num?)?.toInt() ?? 0,
      walletShortfall: _parseMoney(j['wallet_shortfall'] ?? pricing?['wallet_shortfall']),
      walletCanPayNow: j['wallet_can_pay_now'] == true ||
          pricing?['wallet_can_pay_now'] == true,
      topUpRequired:
          j['top_up_required'] == true || pricing?['top_up_required'] == true,
      requiredTopUpAmount:
          _parseMoney(j['required_top_up_amount'] ?? pricing?['required_top_up_amount']),
      suggestedTopUpAmount:
          _parseMoney(j['suggested_top_up_amount'] ?? pricing?['suggested_top_up_amount']),
      promoCode: (j['promo_code'] ?? '').toString(),
      promoValid: j['promo_valid'] == true || j['promo_valid'] == 1,
      promoMessage: (j['promo_message'] ?? '').toString(),
      promoDiscountAmount: _parseMoney(j['promo_discount_amount'] ?? (j['pricing'] as Map?)?['discounts']),
      priceLines: (j['price_lines'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      shipments: shipments,
    );
  }
}

List<String> _defaultAllowedMethods(String mode) {
  switch (mode) {
    case 'wallet_only':
      return const ['wallet'];
    case 'gateway_only':
      return const ['gateway'];
    case 'wallet_and_gateway':
      return const ['wallet', 'gateway'];
    default:
      return const ['gateway'];
  }
}

double? _parseMoney(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  // Keep digits, minus, dot.
  final cleaned = s.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  return double.tryParse(cleaned);
}
