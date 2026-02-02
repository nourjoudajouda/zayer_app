import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';

/// Mock orders list. Replace with GET /api/orders later.
Future<List<OrderModel>> _fetchOrders() async {
  await Future.delayed(const Duration(milliseconds: 400));
  return [
    const OrderModel(
      id: '1',
      origin: OrderOrigin.multiOrigin,
      status: OrderStatus.inTransit,
      orderNumber: 'ZYR-2024-8842',
      placedDate: 'Placed Nov 12, 2024',
      totalAmount: '\$312.40',
      estimatedDelivery: 'Est. delivery Dec 2–5, 2024',
    ),
    const OrderModel(
      id: '2',
      origin: OrderOrigin.turkey,
      status: OrderStatus.delivered,
      orderNumber: 'ZYR-2024-7721',
      placedDate: 'Placed Oct 28, 2024',
      deliveredOn: 'Delivered Nov 8, 2024',
      totalAmount: '\$189.00',
    ),
    const OrderModel(
      id: '3',
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

/// Filter: All | In Progress | Delivered | Cancelled. API can support ?status= later.
enum OrdersFilter {
  all,
  inProgress,
  delivered,
  cancelled,
}

final ordersFilterProvider =
    StateProvider<OrdersFilter>((ref) => OrdersFilter.all);

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final async = ref.watch(ordersProvider);
  final filter = ref.watch(ordersFilterProvider);
  return async.when(
    data: (list) {
      final filtered = list.where((o) {
        switch (filter) {
          case OrdersFilter.all:
            return true;
          case OrdersFilter.inProgress:
            return o.status == OrderStatus.inTransit;
          case OrdersFilter.delivered:
            return o.status == OrderStatus.delivered;
          case OrdersFilter.cancelled:
            return o.status == OrderStatus.cancelled;
        }
      }).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
