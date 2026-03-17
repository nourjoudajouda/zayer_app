/// Review & Pay (checkout) model. API: GET /api/checkout/review, POST confirm later.
class CheckoutShipmentItem {
  const CheckoutShipmentItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.eta,
    this.imageUrl,
    this.reviewed = true,
    this.shippingCost,
  });

  final String name;
  final String price;
  final int quantity;
  final String eta;
  final String? imageUrl;
  final bool reviewed;
  final String? shippingCost;
}

class CheckoutShipment {
  const CheckoutShipment({
    required this.originLabel,
    required this.items,
    this.reviewed = true,
  });

  final String originLabel;
  final List<CheckoutShipmentItem> items;
  final bool reviewed;
}

class CheckoutReviewModel {
  const CheckoutReviewModel({
    this.shippingAddressShort = '',
    this.consolidationSavings = '',
    this.walletBalanceEnabled = true,
    this.walletBalance = '',
    this.subtotal = '',
    this.shipping = '',
    this.insurance = '',
    this.total = '',
    this.amountDueNow,
    this.walletApplied,
    required this.shipments,
  });

  final String shippingAddressShort;
  final String consolidationSavings;
  final bool walletBalanceEnabled;
  final String walletBalance;
  final String subtotal;
  final String shipping;
  final String insurance;
  final String total;
  /// Amount due now after wallet application (backend source of truth).
  final double? amountDueNow;
  /// Wallet amount applied (if provided by backend).
  final double? walletApplied;
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
          reviewed: im['reviewed'] == true,
          shippingCost: im['shipping_cost'] as String?,
        );
      }).toList() ?? [];
      return CheckoutShipment(
        originLabel: (sm['origin_label'] ?? '').toString(),
        items: items,
        reviewed: sm['reviewed'] == true,
      );
    }).toList() ?? [];
    return CheckoutReviewModel(
      shippingAddressShort: (j['shipping_address_short'] ?? '').toString(),
      consolidationSavings: (j['consolidation_savings'] ?? '\$0.00').toString(),
      walletBalanceEnabled: j['wallet_balance_enabled'] != false,
      walletBalance: (j['wallet_balance'] ?? '\$0.00').toString(),
      subtotal: (j['subtotal'] ?? '\$0.00').toString(),
      shipping: (j['shipping'] ?? '\$0.00').toString(),
      insurance: (j['insurance'] ?? '\$0.00').toString(),
      total: (j['total'] ?? '\$0.00').toString(),
      amountDueNow: _parseMoney(j['amount_due_now'] ?? j['due_now'] ?? j['amount_due']),
      walletApplied: _parseMoney(j['wallet_applied'] ?? j['wallet_applied_amount']),
      shipments: shipments,
    );
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
