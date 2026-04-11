// API models for warehouse + outbound shipments (second payment).

class WarehouseItemApi {
  const WarehouseItemApi({
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
  final WarehouseReceiptApi? receipt;

  factory WarehouseItemApi.fromJson(Map<String, dynamic> j) {
    final r = j['receipt'];
    return WarehouseItemApi(
      id: j['id']?.toString() ?? '',
      name: (j['name'] ?? '').toString(),
      imageUrl: j['image_url'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      price: (j['price'] as num?)?.toDouble() ?? 0,
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      dimensions: j['dimensions'] as String?,
      receipt: r is Map<String, dynamic> ? WarehouseReceiptApi.fromJson(r) : null,
    );
  }
}

class WarehouseReceiptApi {
  const WarehouseReceiptApi({
    this.receivedAt,
    this.receivedWeight,
    this.receivedLength,
    this.receivedWidth,
    this.receivedHeight,
    this.images = const [],
    this.conditionNotes,
    this.specialHandlingType,
    this.additionalFeeAmount = 0,
  });

  final String? receivedAt;
  final double? receivedWeight;
  final double? receivedLength;
  final double? receivedWidth;
  final double? receivedHeight;
  final List<String> images;
  final String? conditionNotes;
  final String? specialHandlingType;
  final double additionalFeeAmount;

  factory WarehouseReceiptApi.fromJson(Map<String, dynamic> j) {
    final rawImages = j['images'];
    final imgs = <String>[];
    if (rawImages is List) {
      for (final e in rawImages) {
        if (e is String && e.trim().isNotEmpty) imgs.add(e.trim());
      }
    }
    return WarehouseReceiptApi(
      receivedAt: j['received_at'] as String?,
      receivedWeight: (j['received_weight'] as num?)?.toDouble(),
      receivedLength: (j['received_length'] as num?)?.toDouble(),
      receivedWidth: (j['received_width'] as num?)?.toDouble(),
      receivedHeight: (j['received_height'] as num?)?.toDouble(),
      images: imgs,
      conditionNotes: j['condition_notes'] as String?,
      specialHandlingType: j['special_handling_type'] as String?,
      additionalFeeAmount: (j['additional_fee_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OutboundShipmentApi {
  const OutboundShipmentApi({
    required this.id,
    required this.status,
    this.carrier,
    this.trackingNumber,
    this.finalBoxImage,
    required this.shippingCost,
    required this.additionalFeesTotal,
    required this.totalShippingPayment,
    required this.currency,
    this.items = const [],
    this.paymentStatus,
    this.destinationSummary,
  });

  final String id;
  final String status;
  final String? carrier;
  final String? trackingNumber;
  final String? finalBoxImage;
  final double shippingCost;
  final double additionalFeesTotal;
  final double totalShippingPayment;
  final String currency;
  final List<ShipmentLineApi> items;
  final String? paymentStatus;
  final String? destinationSummary;

  factory OutboundShipmentApi.fromJson(Map<String, dynamic> j) {
    final itemsRaw = j['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(ShipmentLineApi.fromJson)
            .toList()
        : const <ShipmentLineApi>[];
    return OutboundShipmentApi(
      id: j['id']?.toString() ?? '',
      status: (j['status'] ?? '').toString(),
      carrier: j['carrier'] as String?,
      trackingNumber: j['tracking_number'] as String?,
      finalBoxImage: j['final_box_image'] as String?,
      shippingCost: (j['shipping_cost'] as num?)?.toDouble() ?? 0,
      additionalFeesTotal: (j['additional_fees_total'] as num?)?.toDouble() ?? 0,
      totalShippingPayment: (j['total_shipping_payment'] as num?)?.toDouble() ?? 0,
      currency: (j['currency'] ?? 'USD').toString(),
      items: items,
      paymentStatus: j['payment_status'] as String?,
      destinationSummary: j['destination_summary'] as String?,
    );
  }
}

class ShipmentLineApi {
  const ShipmentLineApi({
    required this.orderLineItemId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    this.weightKg,
    this.dimensions,
    this.receipt,
  });

  final String orderLineItemId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double? weightKg;
  final String? dimensions;
  final WarehouseReceiptApi? receipt;

  factory ShipmentLineApi.fromJson(Map<String, dynamic> j) {
    final r = j['receipt'];
    return ShipmentLineApi(
      orderLineItemId: j['order_line_item_id']?.toString() ?? '',
      name: (j['name'] ?? '').toString(),
      imageUrl: j['image_url'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      dimensions: j['dimensions'] as String?,
      receipt: r is Map<String, dynamic> ? WarehouseReceiptApi.fromJson(r) : null,
    );
  }
}
