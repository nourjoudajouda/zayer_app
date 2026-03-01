import 'package:flutter/material.dart';

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

/// Single tracking event for a shipment.
class OrderTrackingEvent {
  const OrderTrackingEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isHighlighted = false,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isHighlighted;
}

/// Line item in an order (product).
class OrderLineItem {
  const OrderLineItem({
    required this.id,
    required this.name,
    required this.storeName,
    required this.sku,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.badges = const [], // e.g. 'Customs', 'Lithium'
    this.weightKg,
    this.dimensions,
    this.shippingMethod,
  });
  final String id;
  final String name;
  final String storeName;
  final String sku;
  final String price;
  final int quantity;
  final String? imageUrl;
  final List<String> badges;
  final double? weightKg;
  final String? dimensions;
  final String? shippingMethod;
}

/// Price line in breakdown.
class OrderPriceLine {
  const OrderPriceLine({required this.label, required this.amount, this.isDiscount = false});
  final String label;
  final String amount;
  final bool isDiscount;
}

/// One shipment leg (e.g. USA Shipment, Turkey Shipment).
class OrderShipment {
  const OrderShipment({
    required this.id,
    required this.countryCode,
    required this.countryLabel,
    required this.shippingMethod,
    required this.eta,
    required this.items,
    required this.trackingEvents,
    this.subtotal,
    this.shippingFee,
    this.customsDuties,
    this.grossWeightKg,
    this.dimensions,
    this.insuranceConfirmed = false,
    this.statusTags = const [],
  });
  final String id;
  final String countryCode;
  final String countryLabel;
  final String shippingMethod;
  final String eta;
  final List<OrderLineItem> items;
  final List<OrderTrackingEvent> trackingEvents;
  final String? subtotal;
  final String? shippingFee;
  final String? customsDuties;
  final double? grossWeightKg;
  final String? dimensions;
  final bool insuranceConfirmed;
  final List<String> statusTags;
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
    this.shippingAddress,
    this.shipments = const [],
    this.priceLines = const [],
    this.consolidationSavings,
    this.paymentMethodLabel,
    this.paymentMethodLastFour,
    this.invoiceIssueDate,
    this.transactionId,
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
  final String? shippingAddress;
  final List<OrderShipment> shipments;
  final List<OrderPriceLine> priceLines;
  final String? consolidationSavings;
  final String? paymentMethodLabel;
  final String? paymentMethodLastFour;
  final String? invoiceIssueDate;
  final String? transactionId;

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
