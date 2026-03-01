import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';

/// Mock orders list with full detail. Replace with GET /api/orders later.
Future<List<OrderModel>> _fetchOrders() async {
  await Future.delayed(const Duration(milliseconds: 400));
  return [
    OrderModel(
      id: '1',
      origin: OrderOrigin.usa,
      status: OrderStatus.inTransit,
      orderNumber: 'ZY-882910',
      placedDate: 'Oct 12, 2023',
      totalAmount: '\$1,364.00',
      estimatedDelivery: 'Est. delivery Oct 16, 2023',
      shippingAddress: '123 Logistics Way, Suite 400, NY 10001',
      shipments: [
        OrderShipment(
          id: 'ZY-U01',
          countryCode: 'US',
          countryLabel: 'USA Shipment',
          shippingMethod: 'Air Express',
          eta: 'Oct 28 - 30',
          statusTags: ['CONSOLIDATED', 'ON TIME'],
          items: [
            OrderLineItem(
              id: 'i1',
              name: 'iPhone 15 Pro Max',
              storeName: 'Apple Store',
              sku: 'AP-15-256-BK',
              price: '\$1,199.00',
              quantity: 1,
              badges: ['Customs', 'Lithium'],
              weightKg: 0.5,
              dimensions: '12x8x4 cm',
              shippingMethod: 'Air Express',
            ),
          ],
          trackingEvents: [
            OrderTrackingEvent(
              title: 'Arrived at Warehouse',
              subtitle: 'New York, USA • Oct 12, 10:45 AM',
              icon: Icons.home_outlined,
            ),
            OrderTrackingEvent(
              title: 'Customs Cleared',
              subtitle: 'Jamaica, NY • Oct 14, 02:20 PM',
              icon: Icons.swap_horiz,
            ),
            OrderTrackingEvent(
              title: 'Out for Delivery',
              subtitle: 'Estimated Oct 16, 2023',
              icon: Icons.local_shipping_outlined,
              isHighlighted: true,
            ),
          ],
          subtotal: '\$1,199.00',
          shippingFee: '\$45.00',
          customsDuties: '\$120.00',
          grossWeightKg: 0.5,
          dimensions: '12×8×4 cm',
          insuranceConfirmed: true,
        ),
      ],
      priceLines: [
        const OrderPriceLine(label: 'Items Total (1)', amount: '\$1,199.00'),
        const OrderPriceLine(label: 'USA Shipping Fee', amount: '\$45.00'),
        const OrderPriceLine(label: 'Customs & Duties', amount: '\$120.00'),
        const OrderPriceLine(label: 'Consolidation Savings', amount: '-\$15.00', isDiscount: true),
      ],
      consolidationSavings: '-\$15.00',
      paymentMethodLabel: 'Apple Pay',
      paymentMethodLastFour: '4492',
      invoiceIssueDate: 'Oct 24, 2023',
      transactionId: 'TXN-88220019',
    ),
    OrderModel(
      id: '2',
      origin: OrderOrigin.multiOrigin,
      status: OrderStatus.inTransit,
      orderNumber: 'ZY-98210',
      placedDate: 'Oct 20, 2023',
      totalAmount: '\$390.50',
      estimatedDelivery: 'Est. delivery Oct 28 – Nov 15, 2023',
      shippingAddress: '123 Business Way, Business Bay Dubai, United Arab Emirates',
      shipments: [
        OrderShipment(
          id: 'ZY-U01',
          countryCode: 'US',
          countryLabel: 'USA Shipment',
          shippingMethod: 'Air Express',
          eta: 'Oct 28 - 30',
          statusTags: ['CONSOLIDATED', 'ON TIME'],
          items: [
            const OrderLineItem(
              id: 'i2a',
              name: 'Premium Wireless Headphones',
              storeName: 'Tech Store',
              sku: 'WH-MB-01',
              price: '\$199.00',
              quantity: 1,
            ),
            const OrderLineItem(
              id: 'i2b',
              name: 'Tech Protection Sleeve',
              storeName: 'Tech Store',
              sku: 'SL-SG-01',
              price: '\$45.00',
              quantity: 1,
            ),
          ],
          trackingEvents: [
            OrderTrackingEvent(
              title: 'Waiting for items to arrive at warehouse',
              subtitle: 'Oct 22, 09:15 AM',
              icon: Icons.check_circle_outlined,
            ),
            OrderTrackingEvent(
              title: 'Processed at Export Hub',
              subtitle: 'New Jersey, USA • Oct 24, 10:00 AM',
              icon: Icons.check_circle_outlined,
            ),
            OrderTrackingEvent(
              title: 'Customs Clearance',
              subtitle: 'Processing documentation for import',
              icon: Icons.description_outlined,
              isHighlighted: true,
            ),
            OrderTrackingEvent(
              title: 'International Shipping',
              subtitle: 'Estimated Oct 28',
              icon: Icons.flight_outlined,
            ),
          ],
          subtotal: '\$244.00',
          shippingFee: '\$45.00',
          customsDuties: '\$18.50',
          grossWeightKg: 2.5,
          dimensions: '30×20×15 cm',
          insuranceConfirmed: true,
        ),
        OrderShipment(
          id: 'ZY-T02',
          countryCode: 'TR',
          countryLabel: 'Turkey Shipment',
          shippingMethod: 'Sea Cargo',
          eta: 'Nov 12 - 15',
          statusTags: ['SINGLE ITEM', 'ARRIVED AT HUB'],
          items: const [],
          trackingEvents: [],
          subtotal: '\$64.00',
          shippingFee: '\$22.00',
          customsDuties: '\$4.00',
        ),
      ],
      priceLines: const [
        OrderPriceLine(label: 'USA Shipment Subtotal', amount: '\$244.00'),
        OrderPriceLine(label: 'Intl. Shipping (Express)', amount: '\$45.00'),
        OrderPriceLine(label: 'Customs & Duties', amount: '\$18.50'),
        OrderPriceLine(label: 'Turkey Shipment Subtotal', amount: '\$64.00'),
        OrderPriceLine(label: 'Intl. Shipping (Sea)', amount: '\$22.00'),
        OrderPriceLine(label: 'Customs & Duties', amount: '\$4.00'),
        OrderPriceLine(label: 'Consolidated Insurance', amount: '\$5.00'),
        OrderPriceLine(label: 'Consolidation Savings', amount: '-\$12.00', isDiscount: true),
      ],
      consolidationSavings: '-\$12.00',
      paymentMethodLabel: 'Apple Pay',
      paymentMethodLastFour: '9921',
      invoiceIssueDate: 'Oct 24, 2023',
      transactionId: 'TXN-88220019',
    ),
    const OrderModel(
      id: '3',
      origin: OrderOrigin.turkey,
      status: OrderStatus.delivered,
      orderNumber: 'ZYR-2024-7721',
      placedDate: 'Placed Oct 28, 2024',
      deliveredOn: 'Delivered Nov 8, 2024',
      totalAmount: '\$189.00',
    ),
    const OrderModel(
      id: '4',
      origin: OrderOrigin.usa,
      status: OrderStatus.cancelled,
      orderNumber: 'ZYR-2024-6503',
      placedDate: 'Placed Oct 15, 2024',
      totalAmount: '\$95.20',
      refundStatus: 'Refund completed',
    ),
  ];
}

final ordersProvider = FutureProvider<List<OrderModel>>((ref) => _fetchOrders());

/// Filter by status: All | In Progress | Delivered | Cancelled.
enum OrdersFilter {
  all,
  inProgress,
  delivered,
  cancelled,
}

/// Filter by order origin (shipment source).
enum OrdersOriginFilter {
  all,
  usa,
  turkey,
  multiOrigin,
}

/// Sort orders.
enum OrdersSortOption {
  newestFirst,
  oldestFirst,
  amountHighToLow,
  amountLowToHigh,
}

final ordersFilterProvider =
    StateProvider<OrdersFilter>((ref) => OrdersFilter.all);

final ordersOriginFilterProvider =
    StateProvider<OrdersOriginFilter>((ref) => OrdersOriginFilter.all);

final ordersSortProvider =
    StateProvider<OrdersSortOption>((ref) => OrdersSortOption.newestFirst);

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final async = ref.watch(ordersProvider);
  final statusFilter = ref.watch(ordersFilterProvider);
  final originFilter = ref.watch(ordersOriginFilterProvider);
  final sortOption = ref.watch(ordersSortProvider);
  return async.when(
    data: (list) {
      var filtered = list.where((o) {
        switch (statusFilter) {
          case OrdersFilter.all:
            break;
          case OrdersFilter.inProgress:
            if (o.status != OrderStatus.inTransit) return false;
            break;
          case OrdersFilter.delivered:
            if (o.status != OrderStatus.delivered) return false;
            break;
          case OrdersFilter.cancelled:
            if (o.status != OrderStatus.cancelled) return false;
            break;
        }
        switch (originFilter) {
          case OrdersOriginFilter.all:
            break;
          case OrdersOriginFilter.usa:
            if (o.origin != OrderOrigin.usa) return false;
            break;
          case OrdersOriginFilter.turkey:
            if (o.origin != OrderOrigin.turkey) return false;
            break;
          case OrdersOriginFilter.multiOrigin:
            if (o.origin != OrderOrigin.multiOrigin) return false;
            break;
        }
        return true;
      }).toList();

      switch (sortOption) {
        case OrdersSortOption.newestFirst:
          break;
        case OrdersSortOption.oldestFirst:
          filtered = filtered.reversed.toList();
          break;
        case OrdersSortOption.amountHighToLow:
          filtered = List.from(filtered)
            ..sort((a, b) => _parseAmount(b.totalAmount).compareTo(_parseAmount(a.totalAmount)));
          break;
        case OrdersSortOption.amountLowToHigh:
          filtered = List.from(filtered)
            ..sort((a, b) => _parseAmount(a.totalAmount).compareTo(_parseAmount(b.totalAmount)));
          break;
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

double _parseAmount(String s) {
  final cleaned = s.replaceAll(RegExp(r'[^\d.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

/// Single order by id for detail/tracking/invoice screens.
final orderByIdProvider = FutureProvider.family<OrderModel?, String>((ref, id) async {
  final list = await ref.watch(ordersProvider.future);
  try {
    return list.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
});
