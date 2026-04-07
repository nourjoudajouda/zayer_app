/// API models for warehouse / outbound shipments (second payment).

class WarehouseItemApi {
  WarehouseItemApi({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    this.weightKg,
    this.dimensions,
    this.receipt,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final double? weightKg;
  final String? dimensions;
  final Map<String, dynamic>? receipt;

  factory WarehouseItemApi.fromJson(Map<String, dynamic> j) {
    return WarehouseItemApi(
      id: j['id']?.toString() ?? '',
      name: (j['name'] ?? '').toString(),
      imageUrl: j['image_url'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      dimensions: j['dimensions'] as String?,
      receipt: j['receipt'] is Map<String, dynamic> ? Map<String, dynamic>.from(j['receipt'] as Map) : null,
    );
  }
}

class OutboundShipmentApi {
  OutboundShipmentApi({
    required this.id,
    required this.status,
    this.carrier,
    this.trackingNumber,
    this.finalBoxImage,
    this.dispatchedAt,
    required this.shippingCost,
    required this.additionalFeesTotal,
    required this.totalShippingPayment,
    required this.currency,
    required this.items,
  });

  final String id;
  final String status;
  final String? carrier;
  final String? trackingNumber;
  final String? finalBoxImage;
  final String? dispatchedAt;
  final double shippingCost;
  final double additionalFeesTotal;
  final double totalShippingPayment;
  final String currency;
  final List<Map<String, dynamic>> items;

  factory OutboundShipmentApi.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'];
    final items = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return OutboundShipmentApi(
      id: j['id']?.toString() ?? '',
      status: (j['status'] ?? '').toString(),
      carrier: j['carrier'] as String?,
      trackingNumber: j['tracking_number'] as String?,
      finalBoxImage: j['final_box_image'] as String?,
      dispatchedAt: j['dispatched_at'] as String?,
      shippingCost: (j['shipping_cost'] as num?)?.toDouble() ?? 0,
      additionalFeesTotal: (j['additional_fees_total'] as num?)?.toDouble() ?? 0,
      totalShippingPayment: (j['total_shipping_payment'] as num?)?.toDouble() ?? 0,
      currency: (j['currency'] ?? 'USD').toString(),
      items: items,
    );
  }
}
