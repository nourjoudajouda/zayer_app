import 'package:flutter/material.dart';

/// Order list item model. API: GET /api/orders later.
/// Status values align with backend and user-facing labels.
enum OrderStatus {
  pendingReview,
  pendingPayment,
  paid,
  processing,
  shipped,
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
      case OrderStatus.pendingReview:
        return 'Pending review';
      case OrderStatus.pendingPayment:
        return 'Pending payment';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.inTransit:
        return 'In transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get canTrack =>
      status == OrderStatus.shipped || status == OrderStatus.inTransit;
  bool get canBuyAgain => status == OrderStatus.delivered;

  static OrderStatus _statusFrom(String? s) {
    if (s == null || s.isEmpty) return OrderStatus.pendingPayment;
    final lower = s.toString().toLowerCase().replaceAll('-', '_');
    switch (lower) {
      case 'pending_review':
        return OrderStatus.pendingReview;
      case 'pending_payment':
        return OrderStatus.pendingPayment;
      case 'paid':
        return OrderStatus.paid;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingPayment;
    }
  }

  static OrderOrigin _originFrom(String? s) {
    if (s == 'multi_origin') return OrderOrigin.multiOrigin;
    if (s == 'turkey') return OrderOrigin.turkey;
    return OrderOrigin.usa;
  }

  static OrderModel fromJson(Map<String, dynamic> j) {
    final shipmentsList = j['shipments'] as List<dynamic>?;
    final shipments = shipmentsList
            ?.map((s) => _shipmentFromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    final priceLinesList = j['price_lines'] as List<dynamic>?;
    final priceLines = priceLinesList
            ?.map((e) {
              final m = e is Map<String, dynamic> ? e : null;
              if (m == null) return null;
              return OrderPriceLine(
                label: (m['label'] ?? '').toString(),
                amount: (m['amount'] ?? '').toString(),
                isDiscount: m['is_discount'] == true,
              );
            })
            .whereType<OrderPriceLine>()
            .toList() ??
        [];
    return OrderModel(
      id: (j['id'] ?? '').toString(),
      origin: _originFrom(j['origin'] as String?),
      status: _statusFrom(j['status'] as String?),
      orderNumber: (j['order_number'] ?? '').toString(),
      placedDate: (j['placed_date'] ?? '').toString(),
      deliveredOn: j['delivered_on'] as String?,
      totalAmount: (j['total_amount'] ?? '\$0.00').toString(),
      refundStatus: j['refund_status'] as String?,
      estimatedDelivery: j['estimated_delivery'] as String?,
      shippingAddress: j['shipping_address'] as String?,
      shipments: shipments,
      priceLines: priceLines,
      consolidationSavings: j['consolidation_savings'] as String?,
      paymentMethodLabel: j['payment_method_label'] as String?,
      paymentMethodLastFour: j['payment_method_last_four'] as String?,
      invoiceIssueDate: j['invoice_issue_date'] as String?,
      transactionId: j['transaction_id'] as String?,
    );
  }

  static OrderShipment _shipmentFromJson(Map<String, dynamic> s) {
    final itemsList = s['items'] as List<dynamic>?;
    final items = itemsList
            ?.map((i) => OrderLineItem(
                  id: (i['id'] ?? '').toString(),
                  name: (i['name'] ?? '').toString(),
                  storeName: (i['store_name'] ?? '').toString(),
                  sku: (i['sku'] ?? '').toString(),
                  price: (i['price'] ?? '\$0.00').toString(),
                  quantity: (i['quantity'] as int?) ?? 1,
                  imageUrl: i['image_url'] as String?,
                  weightKg: (i['weight_kg'] as num?)?.toDouble(),
                  dimensions: (i['dimensions'] ?? '').toString().trim().isEmpty ? null : (i['dimensions'] ?? '').toString(),
                  shippingMethod: (i['shipping_method'] ?? '').toString().trim().isEmpty ? null : (i['shipping_method'] ?? '').toString(),
                ))
            .toList() ??
        [];
    final eventsList = s['tracking_events'] as List<dynamic>?;
    final events = eventsList
            ?.map((e) => OrderTrackingEvent(
                  title: (e['title'] ?? '').toString(),
                  subtitle: (e['subtitle'] ?? '').toString(),
                  icon: Icons.check_circle_outlined,
                  isHighlighted: e['is_highlighted'] == true,
                ))
            .toList() ??
        [];
    final statusTagsRaw = s['status_tags'];
    final statusTags = statusTagsRaw is List
        ? statusTagsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const <String>[];
    return OrderShipment(
      id: (s['id'] ?? '').toString(),
      countryCode: (s['country_code'] ?? '').toString(),
      countryLabel: (s['country_label'] ?? '').toString(),
      shippingMethod: (s['shipping_method'] ?? '').toString(),
      eta: (s['eta'] ?? '').toString(),
      items: items,
      trackingEvents: events,
      subtotal: s['subtotal'] as String?,
      shippingFee: s['shipping_fee'] as String?,
      customsDuties: s['customs_duties'] as String?,
      grossWeightKg: (s['gross_weight_kg'] as num?)?.toDouble(),
      dimensions: (s['dimensions'] ?? '').toString().trim().isEmpty ? null : (s['dimensions'] ?? '').toString(),
      insuranceConfirmed: s['insurance_confirmed'] == true,
      statusTags: statusTags,
    );
  }
}
