/// Optional data when opening [PurchaseAssistantSubmitScreen] from Add via Link.
class PurchaseAssistantPrefill {
  const PurchaseAssistantPrefill({
    required this.sourceUrl,
    this.title,
    this.details,
    this.quantity = 1,
    this.variantDetails,
    this.customerEstimatedPrice,
    this.currency = 'USD',
    this.imageUrl,
  });

  final String sourceUrl;
  final String? title;
  final String? details;
  final int quantity;
  final String? variantDetails;
  final double? customerEstimatedPrice;
  final String currency;
  final String? imageUrl;
}
