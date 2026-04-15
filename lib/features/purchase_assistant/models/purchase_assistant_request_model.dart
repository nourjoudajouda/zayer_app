class PurchaseAssistantRequestModel {
  const PurchaseAssistantRequestModel({
    required this.id,
    required this.sourceUrl,
    this.sourceDomain,
    this.title,
    this.details,
    required this.quantity,
    this.variantDetails,
    this.customerEstimatedPrice,
    this.currency,
    this.imageUrls = const [],
    this.adminProductPrice,
    this.adminServiceFee,
    this.adminNotes,
    required this.status,
    required this.origin,
    this.convertedOrderId,
    this.createdAt,
  });

  final String id;
  final String sourceUrl;
  final String? sourceDomain;
  final String? title;
  final String? details;
  final int quantity;
  final String? variantDetails;
  final double? customerEstimatedPrice;
  final String? currency;
  final List<String> imageUrls;
  final double? adminProductPrice;
  final double? adminServiceFee;
  final String? adminNotes;
  final String status;
  final String origin;
  final String? convertedOrderId;
  final String? createdAt;

  factory PurchaseAssistantRequestModel.fromJson(Map<String, dynamic> j) {
    final imgs = j['image_urls'];
    return PurchaseAssistantRequestModel(
      id: (j['id'] ?? '').toString(),
      sourceUrl: (j['source_url'] ?? '').toString(),
      sourceDomain: j['source_domain'] as String?,
      title: j['title'] as String?,
      details: j['details'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      variantDetails: j['variant_details'] as String?,
      customerEstimatedPrice: (j['customer_estimated_price'] as num?)?.toDouble(),
      currency: j['currency'] as String?,
      imageUrls: imgs is List
          ? imgs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      adminProductPrice: (j['admin_product_price'] as num?)?.toDouble(),
      adminServiceFee: (j['admin_service_fee'] as num?)?.toDouble(),
      adminNotes: j['admin_notes'] as String?,
      status: (j['status'] ?? '').toString(),
      origin: (j['origin'] ?? '').toString(),
      convertedOrderId: j['converted_order_id'] != null
          ? j['converted_order_id'].toString()
          : null,
      createdAt: j['created_at'] as String?,
    );
  }
}
