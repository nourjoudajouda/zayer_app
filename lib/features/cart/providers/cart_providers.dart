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

/// ID of the cart item currently being updated/removed (for button loader).
final loadingCartItemIdProvider = StateProvider<String?>((ref) => null);

/// True while clear-cart API is in progress (full-screen loader on cart).
final clearingCartProvider = StateProvider<bool>((ref) => false);

/// True while navigating to checkout / payment (loader on Proceed to Checkout button).
final proceedingToCheckoutProvider = StateProvider<bool>((ref) => false);

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._repository) : super([]) {
    loadItems();
  }

  final CartRepository _repository;

  Future<void> loadItems() async {
    await _repository.loadItems();
    state = List.from(_repository.items);
  }

  /// Returns true if item was added, false if same product+variation already in cart.
  Future<bool> addItem(CartItem item) async {
    if (_isDuplicate(item)) return false;
    await _repository.addItem(item);
    state = List.from(_repository.items);
    return true;
  }

  static String _normVariation(String? v) => (v ?? '').trim();

  bool _isDuplicate(CartItem item) {
    final url = item.productUrl.trim();
    final variation = _normVariation(item.variationText);
    return state.any((e) =>
        e.productUrl.trim() == url && _normVariation(e.variationText) == variation);
  }

  Future<void> updateQuantity(String id, int quantity) async {
    await _repository.updateQuantity(id, quantity);
    // Refresh from backend to keep totals/shipping as source of truth.
    await _repository.loadItems();
    state = List.from(_repository.items);
  }

  Future<void> removeItem(String id) async {
    await _repository.removeItem(id);
    // Refresh from backend to keep totals/shipping as source of truth.
    await _repository.loadItems();
    state = List.from(_repository.items);
  }

  Future<void> clear() async {
    await _repository.clear();
    state = [];
  }

  int get itemCount => state.length;
  double get totalPrice => state.fold(0.0, (sum, item) => sum + item.totalPrice);
}
