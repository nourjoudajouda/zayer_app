/// Review & Pay (checkout) model. API: GET /api/checkout/review, POST confirm later.
class CheckoutShipmentItem {
  const CheckoutShipmentItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.eta,
    this.imageUrl,
  });

  final String name;
  final String price;
  final int quantity;
  final String eta;
  final String? imageUrl;
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
    this.shippingAddressShort = '123 Main St, Apt 4B, New York, NY 10001',
    this.consolidationSavings = '\$45.00',
    this.walletBalanceEnabled = true,
    this.walletBalance = '\$50.00',
    this.subtotal = '\$245.10',
    this.shipping = '\$22.00',
    this.insurance = '\$5.00',
    this.total = '\$212.10',
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
  final List<CheckoutShipment> shipments;
}
