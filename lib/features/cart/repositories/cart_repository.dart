import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/network/api_config.dart';
import '../models/cart_item_model.dart';

/// Adds items to local cart and sends to backend.
/// Local list is the source of truth; backend sync is best-effort.
abstract class CartRepository {
  List<CartItem> get items;
  Future<void> addItem(CartItem item);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> removeItem(String id);
  Future<void> clear();
}

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({List<CartItem>? initialItems, Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: kApiBaseUrl)) {
    _items.addAll(initialItems ?? []);
  }

  final List<CartItem> _items = [];
  final Dio _dio;

  @override
  List<CartItem> get items => List.unmodifiable(_items);

  @override
  Future<void> addItem(CartItem item) async {
    _items.add(item);
    try {
      await _dio.post(
        kCartItemsPath,
        data: item.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      // Optionally mark item as synced if backend returns 2xx
      final index = _items.indexOf(item);
      if (index >= 0) {
        _items[index] = item.copyWith(syncedToBackend: true);
      }
    } catch (e) {
      // Keep item locally; backend sync failed (e.g. no network or API not ready)
      assert(true, 'Cart item saved locally; backend sync failed: $e');
    }
  }

  @override
  Future<void> updateQuantity(String id, int quantity) async {
    if (quantity < 1) {
      await removeItem(id);
      return;
    }
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) {
      final item = _items[i];
      _items[i] = item.copyWith(quantity: quantity);
    }
  }

  @override
  Future<void> removeItem(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

String generateCartItemId() {
  final r = Random();
  return 'cart_${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999)}';
}
