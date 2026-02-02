/// Order list item model. API: GET /api/orders later.
enum OrderStatus {
  inTransit,
  delivered,
  cancelled,
}

enum OrderOrigin {
  multiOrigin,
  turkey,
  usa,
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.origin,
    required this.status,
    required this.orderNumber,
    required this.placedDate,
    this.deliveredOn,
    required this.totalAmount,
    this.refundStatus,
    this.estimatedDelivery,
  });

  final String id;
  final OrderOrigin origin;
  final OrderStatus status;
  final String orderNumber;
  final String placedDate;
  final String? deliveredOn;
  final String totalAmount;
  final String? refundStatus;
  final String? estimatedDelivery;

  String get originLabel {
    switch (origin) {
      case OrderOrigin.multiOrigin:
        return 'MULTI-ORIGIN SHIPMENT';
      case OrderOrigin.turkey:
        return 'TURKEY ORIGIN';
      case OrderOrigin.usa:
        return 'USA ORIGIN';
    }
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.inTransit:
        return 'IN TRANSIT';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  bool get canTrack => status == OrderStatus.inTransit;
  bool get canBuyAgain => status == OrderStatus.delivered;
}
