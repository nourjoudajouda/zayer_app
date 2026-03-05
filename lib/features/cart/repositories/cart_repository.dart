import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/cart_item_model.dart';

/// Cart: load from API, add/update/remove via API.
abstract class CartRepository {
  List<CartItem> get items;
  Future<void> loadItems();
  Future<void> addItem(CartItem item);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> removeItem(String id);
  Future<void> clear();
}

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;
  final Dio _dio;
  final List<CartItem> _items = [];

  @override
  List<CartItem> get items => List.unmodifiable(_items);

  @override
  Future<void> loadItems() async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/cart/items');
      _items.clear();
      final list = res.data;
      if (list != null) {
        for (final e in list) {
          if (e is Map<String, dynamic>) _items.add(CartItem.fromJson(e));
        }
      }
    } catch (_) {
      _items.clear();
    }
  }

  Map<String, dynamic> _addPayload(CartItem item) => {
        'url': item.productUrl,
        'name': item.name,
        'price': item.unitPrice,
        'quantity': item.quantity,
        'currency': item.currency,
        if (item.imageUrl != null) 'image_url': item.imageUrl,
        if (item.storeKey != null) 'store_key': item.storeKey,
        if (item.storeName != null) 'store_name': item.storeName,
        if (item.productId != null) 'product_id': item.productId,
        if (item.country != null) 'country': item.country,
        'source': item.source,
      };

  @override
  Future<void> addItem(CartItem item) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/cart/items', data: _addPayload(item));
    if (res.statusCode == 201 && res.data != null) {
      _items.add(CartItem.fromJson({...res.data!, 'id': res.data!['id']?.toString()}));
    }
  }

  @override
  Future<void> updateQuantity(String id, int quantity) async {
    if (quantity < 1) {
      await removeItem(id);
      return;
    }
    await _dio.patch('/api/cart/items/$id', data: {'quantity': quantity});
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(quantity: quantity);
  }

  @override
  Future<void> removeItem(String id) async {
    await _dio.delete('/api/cart/items/$id');
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    await _dio.delete('/api/cart');
    _items.clear();
  }
}

String generateCartItemId() {
  final r = Random();
  return 'cart_${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999)}';
}
