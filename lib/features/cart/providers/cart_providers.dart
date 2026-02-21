import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepositoryImpl();
});

final cartItemsProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartNotifier(repo);
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._repository) : super(_repository.items) {
    _loadItems();
  }

  final CartRepository _repository;

  void _loadItems() {
    state = _repository.items;
  }

  Future<void> addItem(CartItem item) async {
    await _repository.addItem(item);
    _loadItems();
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await _repository.updateQuantity(id, quantity);
    _loadItems();
  }

  Future<void> removeItem(String id) async {
    await _repository.removeItem(id);
    _loadItems();
  }

  Future<void> clear() async {
    await _repository.clear();
    _loadItems();
  }

  int get itemCount => state.length;
  double get totalPrice => state.fold(0.0, (sum, item) => sum + item.totalPrice);
}
