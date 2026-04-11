import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

final ordersProvider = FutureProvider<List<OrderModel>>(
  (ref) => _fetchOrders(),
);

/// Filter aligned with execution status groups.
enum OrdersFilter {
  all,
  awaitingReview,
  inExecution,
  delivered,
  cancelled,
}

/// Filter by order origin (shipment source).
enum OrdersOriginFilter { all, usa, turkey, multiOrigin }

/// Sort orders.
enum OrdersSortOption {
  newestFirst,
  oldestFirst,
  amountHighToLow,
  amountLowToHigh,
}

final ordersFilterProvider = StateProvider<OrdersFilter>(
  (ref) => OrdersFilter.all,
);

final ordersOriginFilterProvider = StateProvider<OrdersOriginFilter>(
  (ref) => OrdersOriginFilter.all,
);

final ordersSortProvider = StateProvider<OrdersSortOption>(
  (ref) => OrdersSortOption.newestFirst,
);

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final async = ref.watch(ordersProvider);
  final statusFilter = ref.watch(ordersFilterProvider);
  final originFilter = ref.watch(ordersOriginFilterProvider);
  final sortOption = ref.watch(ordersSortProvider);

  DateTime? parsePlacedDate(String v) {
    var cleaned = v.trim();
    // Some mock/legacy data may include "Placed on <date>"
    cleaned = cleaned
        .replaceFirst(RegExp(r'^\s*placed\s*on\s*', caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return null;

    // Server format: $o->placed_at?->format('M j, Y') => e.g. "Oct 12, 2023"
    try {
      return DateFormat('MMM d, yyyy').parse(cleaned);
    } catch (_) {
      // Fallback for variants like "October 12, 2023".
      try {
        return DateFormat('MMMM d, yyyy').parse(cleaned);
      } catch (_) {
        return null;
      }
    }
  }

  int parseOrderId(String id) => int.tryParse(id.trim()) ?? 0;

  int compareByPlacedDateDesc(OrderModel a, OrderModel b) {
    final da = parsePlacedDate(a.placedDate);
    final db = parsePlacedDate(b.placedDate);
    if (da != null && db != null) {
      final byDate = db.compareTo(da);
      if (byDate != 0) return byDate;
    } else if (da != null && db == null) {
      return -1;
    } else if (da == null && db != null) {
      return 1;
    }

    // Stable fallback: higher id treated as newer.
    return parseOrderId(b.id).compareTo(parseOrderId(a.id));
  }

  int compareByPlacedDateAsc(OrderModel a, OrderModel b) {
    final da = parsePlacedDate(a.placedDate);
    final db = parsePlacedDate(b.placedDate);
    if (da != null && db != null) {
      final byDate = da.compareTo(db);
      if (byDate != 0) return byDate;
    } else if (da != null && db == null) {
      return -1;
    } else if (da == null && db != null) {
      return 1;
    }

    // Stable fallback: lower id treated as older.
    return parseOrderId(a.id).compareTo(parseOrderId(b.id));
  }

  return async.when(
    data: (list) {
      var filtered = list.where((o) {
        switch (statusFilter) {
          case OrdersFilter.all:
            break;
          case OrdersFilter.awaitingReview:
            if (!_isAwaitingReview(o)) return false;
            break;
          case OrdersFilter.inExecution:
            if (!_isInExecution(o)) return false;
            break;
          case OrdersFilter.delivered:
            if (!_isDelivered(o)) return false;
            break;
          case OrdersFilter.cancelled:
            if (!_isCancelled(o)) return false;
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
          filtered = List.from(filtered)..sort(compareByPlacedDateDesc);
          break;
        case OrdersSortOption.oldestFirst:
          filtered = List.from(filtered)..sort(compareByPlacedDateAsc);
          break;
        case OrdersSortOption.amountHighToLow:
          filtered = List.from(filtered)
            ..sort(
              (a, b) => _parseAmount(
                b.totalAmount,
              ).compareTo(_parseAmount(a.totalAmount)),
            );
          break;
        case OrdersSortOption.amountLowToHigh:
          filtered = List.from(filtered)
            ..sort(
              (a, b) => _parseAmount(
                a.totalAmount,
              ).compareTo(_parseAmount(b.totalAmount)),
            );
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

bool _isAwaitingReview(OrderModel o) {
  final k = o.executionStatusKey?.toLowerCase();
  if (k != null && k.isNotEmpty) return k == 'awaiting_review';
  return o.status == OrderStatus.pendingReview;
}

bool _isCancelled(OrderModel o) {
  final k = o.executionStatusKey?.toLowerCase();
  if (k != null && k.isNotEmpty) return k == 'cancelled';
  return o.status == OrderStatus.cancelled;
}

bool _isDelivered(OrderModel o) {
  final k = o.executionStatusKey?.toLowerCase();
  if (k != null && k.isNotEmpty) return k == 'delivered';
  return o.status == OrderStatus.delivered;
}

/// Reviewed / purchase / warehouse / shipment pipeline (not awaiting review, not terminal).
bool _isInExecution(OrderModel o) {
  if (_isDelivered(o) || _isCancelled(o)) return false;
  if (_isAwaitingReview(o)) return false;
  final k = o.executionStatusKey?.toLowerCase();
  if (k != null && k.isNotEmpty) {
    const terminal = {'delivered', 'cancelled'};
    if (terminal.contains(k)) return false;
    return k != 'awaiting_review';
  }
  return o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;
}

/// Single order by id. Fetches from GET /api/orders/{id} for full detail.
final orderByIdProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  id,
) async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>(
      '/api/orders/$id',
    );
    if (res.data != null) return OrderModel.fromJson(res.data!);
  } catch (_) {}
  final list = await ref.watch(ordersProvider.future);
  try {
    return list.firstWhere((o) => o.id == id);
  } catch (_) {
    return null;
  }
});
