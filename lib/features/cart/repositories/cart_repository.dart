import 'dart:math';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/cart_item_model.dart';

/// Result of POST /api/cart/shipping-estimate (paste link preview).
class CartShippingEstimateDto {
  const CartShippingEstimateDto({
    required this.available,
    this.shippingCost,
    this.currency = 'USD',
    this.estimated = false,
    this.message,
    this.destinationCountry,
    this.destinationLabel,
    this.destinationAddressId,
    this.snapshot,
  });

  final bool available;
  final double? shippingCost;
  final String currency;
  final bool estimated;
  final String? message;
  final String? destinationCountry;
  final String? destinationLabel;
  final String? destinationAddressId;

  /// Full quote from [CartShippingEstimateService::quoteForUser] (same as persisted on cart_items.shipping_snapshot).
  final Map<String, dynamic>? snapshot;
}

/// Cart: load from API, add/update/remove via API.
abstract class CartRepository {
  List<CartItem> get items;
  Future<void> loadItems();
  Future<void> addItem(CartItem item);
  Future<void> updateQuantity(String id, int quantity);
  Future<void> removeItem(String id);
  Future<void> clear();

  /// Best-effort shipping preview for paste-link (auth required).
  Future<CartShippingEstimateDto> estimateShipping({
    required int quantity,
    double? weight,
    String? weightUnit,
    double? length,
    double? width,
    double? height,
    String? dimensionUnit,
    String? destinationAddressId,
  });
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

  Map<String, dynamic> _addPayload(CartItem item) {
    final destId = item.destinationAddressId == null || item.destinationAddressId!.isEmpty
        ? null
        : int.tryParse(item.destinationAddressId!);
    return {
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
      if (item.variationText != null && item.variationText!.isNotEmpty) 'variation_text': item.variationText,
      if (item.weight != null) 'weight': item.weight,
      if (item.weightUnit != null) 'weight_unit': item.weightUnit,
      if (item.length != null) 'length': item.length,
      if (item.width != null) 'width': item.width,
      if (item.height != null) 'height': item.height,
      if (item.dimensionUnit != null) 'dimension_unit': item.dimensionUnit,
      if (destId != null) 'destination_address_id': destId,
    };
  }

  @override
  Future<void> addItem(CartItem item) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/cart/items', data: _addPayload(item));
    if (res.statusCode == 201 && res.data != null) {
      final id = res.data!['id']?.toString() ?? generateCartItemId();
      _items.add(CartItem.fromJson({...res.data!, 'id': id}));
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

  @override
  Future<CartShippingEstimateDto> estimateShipping({
    required int quantity,
    double? weight,
    String? weightUnit,
    double? length,
    double? width,
    double? height,
    String? dimensionUnit,
    String? destinationAddressId,
  }) async {
    final destId = destinationAddressId == null || destinationAddressId.isEmpty
        ? null
        : int.tryParse(destinationAddressId);
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/cart/shipping-estimate',
        data: {
          'quantity': quantity < 1 ? 1 : quantity,
          if (weight != null) 'weight': weight,
          if (weightUnit != null && weightUnit.isNotEmpty) 'weight_unit': weightUnit,
          if (length != null) 'length': length,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (dimensionUnit != null && dimensionUnit.isNotEmpty) 'dimension_unit': dimensionUnit,
          if (destId != null) 'destination_address_id': destId,
        },
      );
      final data = res.data;
      if (data == null) {
        return const CartShippingEstimateDto(available: false, message: 'No response');
      }
      final available = data['available'] == true;
      if (!available) {
        return CartShippingEstimateDto(
          available: false,
          message: data['message'] as String?,
        );
      }
      final cost = (data['shipping_cost'] as num?)?.toDouble();
      final destAddrRaw = data['destination_address_id'];
      Map<String, dynamic>? snap;
      final rawSnap = data['snapshot'];
      if (rawSnap is Map<String, dynamic>) {
        snap = rawSnap;
      } else if (rawSnap is Map) {
        snap = Map<String, dynamic>.from(rawSnap);
      }
      return CartShippingEstimateDto(
        available: true,
        shippingCost: cost,
        currency: (data['currency'] as String?)?.trim().isNotEmpty == true
            ? (data['currency'] as String).trim()
            : 'USD',
        estimated: data['estimated'] == true,
        destinationCountry: data['destination_country'] as String?,
        destinationLabel: data['destination_label'] as String?,
        destinationAddressId: destAddrRaw?.toString(),
        snapshot: snap,
      );
    } catch (_) {
      return const CartShippingEstimateDto(available: false);
    }
  }
}

String generateCartItemId() {
  final r = Random();
  return 'cart_${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(99999)}';
}
