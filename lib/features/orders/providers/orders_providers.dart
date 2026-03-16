import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/order_model.dart';

/// Fetch orders from API: GET /api/orders
Future<List<OrderModel>> _fetchOrders() async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/orders');
    final list = res.data;
    if (list != null) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    }
  } catch (_) {}
  return [];
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
            if (o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled) return false;
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

/// Single order by id. Fetches from GET /api/orders/{id} for full detail.
final orderByIdProvider = FutureProvider.family<OrderModel?, String>((ref, id) async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/orders/$id');
    if (res.data != null) return OrderModel.fromJson(res.data!);
  } catch (_) {}
  final list = await ref.watch(ordersProvider.future);
  try {
    return list.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
});
