class PurchaseAssistantRequestModel {
  const PurchaseAssistantRequestModel({
    required this.id,
    required this.sourceUrl,
    this.sourceDomain,
    this.storeDisplayName,
    this.title,
    this.details,
    required this.quantity,
    this.variantDetails,
    this.customerEstimatedPrice,
    this.currency,
    this.imageUrls = const [],
    this.adminProductPrice,
    this.adminServiceFee,
    this.totalPayable,
    this.adminNotes,
    required this.status,
    required this.origin,
    this.convertedOrderId,
    this.statusExplanation,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sourceUrl;
  final String? sourceDomain;
  final String? storeDisplayName;
  final String? title;
  final String? details;
  final int quantity;
  final String? variantDetails;
  final double? customerEstimatedPrice;
  final String? currency;
  final List<String> imageUrls;
  final double? adminProductPrice;
  final double? adminServiceFee;
  /// Server-computed: (admin_product_price × qty) + admin_service_fee when both set.
  final double? totalPayable;
  final String? adminNotes;
  final String status;
  final String origin;
  final String? convertedOrderId;
  final String? statusExplanation;
  final String? createdAt;
  final String? updatedAt;

  factory PurchaseAssistantRequestModel.fromJson(Map<String, dynamic> j) {
    final imgs = j['image_urls'];
    return PurchaseAssistantRequestModel(
      id: (j['id'] ?? '').toString(),
      sourceUrl: (j['source_url'] ?? '').toString(),
      sourceDomain: j['source_domain'] as String?,
      storeDisplayName: j['store_display_name'] as String?,
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
      totalPayable: (j['total_payable'] as num?)?.toDouble(),
      adminNotes: j['admin_notes'] as String?,
      status: (j['status'] ?? '').toString(),
      origin: (j['origin'] ?? '').toString(),
      convertedOrderId: j['converted_order_id'] != null
          ? j['converted_order_id'].toString()
          : null,
      statusExplanation: j['status_explanation'] as String?,
      createdAt: j['created_at'] as String?,
      updatedAt: j['updated_at'] as String?,
    );
  }
}
