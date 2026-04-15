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

enum OrderOrigin { multiOrigin, turkey, usa }

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
  const OrderPriceLine({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });
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
    this.paymentStatus,
    this.paymentReference,
    this.promoCode,
    this.promoDiscountAmount,
    this.walletAppliedAmount,
    this.amountDueNow,
    this.consolidationSavings,
    this.paymentMethodLabel,
    this.paymentMethodLastFour,
    this.invoiceIssueDate,
    this.transactionId,
    this.executionStatusKey,
    this.isPurchaseAssistant = false,
  });

  final String id;
  final OrderOrigin origin;
  final OrderStatus status;
  /// Backend execution status (`execution_status` / `status_key`), when present.
  final String? executionStatusKey;
  final String orderNumber;
  final String placedDate;
  final String? deliveredOn;
  final String totalAmount;
  final String? refundStatus;
  final String? estimatedDelivery;
  final String? shippingAddress;
  final List<OrderShipment> shipments;
  final List<OrderPriceLine> priceLines;
  final String? paymentStatus;
  final String? paymentReference;
  final String? promoCode;
  final double? promoDiscountAmount;
  final double? walletAppliedAmount;
  final double? amountDueNow;
  final String? consolidationSavings;
  final String? paymentMethodLabel;
  final String? paymentMethodLastFour;
  final String? invoiceIssueDate;
  final String? transactionId;

  /// True when order was created from a Purchase Assistant request.
  final bool isPurchaseAssistant;

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
    final k = executionStatusKey;
    if (k != null && k.isNotEmpty) {
      final l = _executionStatusLabelForKey(k);
      if (l != null) return l;
    }
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

  /// Line under the order number, e.g. `Placed on Mar 5, 2026`.
  String get placedOnLine {
    var raw = placedDate.trim();
    if (raw.isEmpty) {
      final inv = invoiceIssueDate?.trim();
      if (inv != null && inv.isNotEmpty) {
        raw = inv;
      }
    }
    if (raw.isEmpty) {
      return 'Placed on —';
    }
    final lower = raw.toLowerCase();
    if (lower.startsWith('placed on')) {
      return raw;
    }
    return 'Placed on $raw';
  }

  /// Uppercase chip text for list, invoice, and detail app bar (aligned with orders cards).
  String get statusChipUpper {
    final k = executionStatusKey?.toLowerCase().replaceAll('-', '_');
    if (k == 'in_transit_to_warehouse' ||
        k == 'partially_shipped' ||
        k == 'fully_shipped') {
      return 'IN TRANSIT';
    }
    if (k == 'delivered') return 'DELIVERED';
    if (k == 'cancelled') return 'CANCELLED';
    switch (status) {
      case OrderStatus.inTransit:
      case OrderStatus.shipped:
        return 'IN TRANSIT';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      default:
        return statusLabel.toUpperCase();
    }
  }

  bool get canTrack =>
      status == OrderStatus.shipped ||
      status == OrderStatus.inTransit ||
      _isExecutionTrackingKey(executionStatusKey);
  bool get canBuyAgain => status == OrderStatus.delivered;

  static bool _isExecutionTrackingKey(String? k) {
    if (k == null || k.isEmpty) return false;
    final lower = k.toLowerCase().replaceAll('-', '_');
    return lower == 'in_transit_to_warehouse' ||
        lower == 'partially_shipped' ||
        lower == 'fully_shipped';
  }

  /// User-facing label aligned with Laravel `OrderExecutionStatus` keys.
  static String? _executionStatusLabelForKey(String raw) {
    final lower = raw.toLowerCase().replaceAll('-', '_');
    switch (lower) {
      case 'awaiting_payment':
        return 'Awaiting payment';
      case 'awaiting_review':
        return 'Awaiting review';
      case 'reviewed':
        return 'Reviewed';
      case 'awaiting_purchase':
        return 'Awaiting purchase';
      case 'partially_purchased':
      case 'fully_purchased':
        return 'Purchased';
      case 'in_transit_to_warehouse':
        return 'In transit';
      case 'partially_at_warehouse':
      case 'fully_at_warehouse':
        return 'At warehouse';
      case 'partially_shipped':
      case 'fully_shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return null;
    }
  }

  /// Maps API `execution_status` / `status_key` (new or legacy) to coarse [OrderStatus].
  static OrderStatus _statusFromUnified(String? s) {
    if (s == null || s.isEmpty) return OrderStatus.pendingPayment;
    final lower = s.toString().toLowerCase().replaceAll('-', '_');
    switch (lower) {
      case 'awaiting_payment':
      case 'pending_payment':
        return OrderStatus.pendingPayment;
      case 'awaiting_review':
      case 'pending_review':
      case 'under_review':
        return OrderStatus.pendingReview;
      case 'reviewed':
      case 'awaiting_purchase':
      case 'partially_purchased':
      case 'fully_purchased':
      case 'partially_at_warehouse':
      case 'fully_at_warehouse':
        return OrderStatus.processing;
      case 'in_transit_to_warehouse':
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'partially_shipped':
      case 'fully_shipped':
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'paid':
        return OrderStatus.paid;
      case 'processing':
        return OrderStatus.processing;
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
    final shipments =
        shipmentsList
            ?.map((s) => _shipmentFromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    final priceLinesList = j['price_lines'] as List<dynamic>?;
    final priceLines =
        priceLinesList
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
    final executionStatusKey = (j['execution_status'] ?? j['status_key'])
        ?.toString()
        .trim();
    final hasExplicitExecution = j['execution_status'] != null &&
        j['execution_status'].toString().trim().isNotEmpty;
    final statusRaw =
        (executionStatusKey != null && executionStatusKey.isNotEmpty
                ? executionStatusKey
                : null) ??
            (j['status_key'] ?? j['status'])?.toString();
    final rawDbStatus = (j['status'] ?? '').toString().toLowerCase().replaceAll(
      '-',
      '_',
    );
    final paymentStatusRaw = (j['payment_status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final needsReview = j['needs_review'] == true;
    var resolvedStatus = _statusFromUnified(statusRaw);

    final paymentIndicatesPaid =
        paymentStatusRaw == 'paid' ||
        paymentStatusRaw == 'completed' ||
        paymentStatusRaw == 'succeeded';

    if (!hasExplicitExecution) {
      resolvedStatus = switch (resolvedStatus) {
        OrderStatus.pendingPayment || OrderStatus.paid
            when paymentIndicatesPaid =>
          needsReview ? OrderStatus.pendingReview : OrderStatus.processing,
        _ => resolvedStatus,
      };

      if (rawDbStatus == 'under_review') {
        resolvedStatus = OrderStatus.pendingReview;
      }

      final due = j['amount_due_now'];
      final dueNum = due is num ? due.toDouble() : double.tryParse('$due');
      if (paymentIndicatesPaid &&
          dueNum != null &&
          dueNum <= 0 &&
          resolvedStatus == OrderStatus.pendingPayment) {
        resolvedStatus = needsReview
            ? OrderStatus.pendingReview
            : OrderStatus.processing;
      }
    }

    return OrderModel(
      id: (j['id'] ?? '').toString(),
      origin: _originFrom(j['origin'] as String?),
      status: resolvedStatus,
      executionStatusKey: executionStatusKey?.isNotEmpty == true
          ? executionStatusKey
          : null,
      orderNumber: (j['order_number'] ?? '').toString(),
      placedDate: (j['placed_date'] ?? '').toString(),
      deliveredOn: j['delivered_on'] as String?,
      totalAmount: (j['total_amount'] ?? '\$0.00').toString(),
      refundStatus: j['refund_status'] as String?,
      estimatedDelivery: j['estimated_delivery'] as String?,
      shippingAddress: j['shipping_address'] as String?,
      shipments: shipments,
      priceLines: priceLines,
      paymentStatus: j['payment_status'] as String?,
      paymentReference: j['payment_reference'] as String?,
      promoCode: j['promo_code'] as String?,
      promoDiscountAmount: (j['promo_discount_amount'] as num?)?.toDouble(),
      walletAppliedAmount: (j['wallet_applied_amount'] as num?)?.toDouble(),
      amountDueNow: (j['amount_due_now'] as num?)?.toDouble(),
      consolidationSavings: j['consolidation_savings'] as String?,
      paymentMethodLabel: j['payment_method_label'] as String?,
      paymentMethodLastFour: j['payment_method_last_four'] as String?,
      invoiceIssueDate: j['invoice_issue_date'] as String?,
      transactionId: j['transaction_id'] as String?,
      isPurchaseAssistant: j['is_purchase_assistant'] == true,
    );
  }

  static OrderShipment _shipmentFromJson(Map<String, dynamic> s) {
    final itemsList = s['items'] as List<dynamic>?;
    final items =
        itemsList
            ?.map(
              (i) => OrderLineItem(
                id: (i['id'] ?? '').toString(),
                name: (i['name'] ?? '').toString(),
                storeName: (i['store_name'] ?? '').toString(),
                sku: (i['sku'] ?? '').toString(),
                price: (i['price'] ?? '\$0.00').toString(),
                quantity: (i['quantity'] as int?) ?? 1,
                imageUrl: i['image_url'] as String?,
                weightKg: (i['weight_kg'] as num?)?.toDouble(),
                dimensions: (i['dimensions'] ?? '').toString().trim().isEmpty
                    ? null
                    : (i['dimensions'] ?? '').toString(),
                shippingMethod:
                    (i['shipping_method'] ?? '').toString().trim().isEmpty
                    ? null
                    : (i['shipping_method'] ?? '').toString(),
              ),
            )
            .toList() ??
        [];
    final eventsList = s['tracking_events'] as List<dynamic>?;
    final events =
        eventsList
            ?.map(
              (e) => OrderTrackingEvent(
                title: (e['title'] ?? '').toString(),
                subtitle: (e['subtitle'] ?? '').toString(),
                icon: Icons.check_circle_outlined,
                isHighlighted: e['is_highlighted'] == true,
              ),
            )
            .toList() ??
        [];
    final statusTagsRaw = s['status_tags'];
    final statusTags = statusTagsRaw is List
        ? statusTagsRaw
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
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
      dimensions: (s['dimensions'] ?? '').toString().trim().isEmpty
          ? null
          : (s['dimensions'] ?? '').toString(),
      insuranceConfirmed: s['insurance_confirmed'] == true,
      statusTags: statusTags,
    );
  }
}
