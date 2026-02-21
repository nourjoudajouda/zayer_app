import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_providers.dart';
import '../models/checkout_review_model.dart';

/// Builds review from current cart. Replace with GET /api/checkout/review later.
CheckoutReviewModel _buildReviewFromCart(List<CartItem> cartItems) {
  if (cartItems.isEmpty) {
    return const CheckoutReviewModel(
      shipments: [],
      subtotal: '\$0.00',
      shipping: '\$0.00',
      insurance: '\$0.00',
      total: '\$0.00',
      consolidationSavings: '\$0.00',
      walletBalance: '\$0.00',
    );
  }

  // Group by country (USA Shipment, Turkey Shipment, etc.)
  final Map<String, List<CartItem>> byCountry = {};
  for (final item in cartItems) {
    final key = item.country ?? 'Other';
    byCountry.putIfAbsent(key, () => []).add(item);
  }

  final shipments = byCountry.entries.map((e) {
    final countryLabel = '${e.key} Shipment';
    final items = e.value;
    return CheckoutShipment(
      originLabel: countryLabel,
      items: items
          .map((item) {
            final shipCost = item.shippingCost ?? 0;
            final shipStr = shipCost > 0
                ? '\$${(shipCost * item.quantity).toStringAsFixed(2)}'
                : null;
            return CheckoutShipmentItem(
              name: item.name,
              price: '\$${item.unitPrice.toStringAsFixed(2)}',
              quantity: item.quantity,
              eta: '4–12 Days',
              imageUrl: item.imageUrl,
              reviewed: item.isReviewed,
              shippingCost: shipStr,
            );
          })
          .toList(),
      reviewed: items.every((i) => i.isReviewed),
    );
  }).toList();

  double subtotal = 0;
  double shippingTotal = 0;
  for (final item in cartItems) {
    subtotal += item.totalPrice;
    shippingTotal += (item.shippingCost ?? 0) * item.quantity;
  }
  if (shippingTotal == 0 && cartItems.isNotEmpty) {
    shippingTotal = 12.0 * cartItems.length;
  }
  final shipping = shippingTotal;
  const insurance = 5.0;
  const consolidationSavings = 45.0;
  const walletBalance = 21.40;
  final total = subtotal + shipping + insurance - consolidationSavings - walletBalance;

  return CheckoutReviewModel(
    shippingAddressShort: '123 Logistics Way, New Yor...',
    consolidationSavings: '\$${consolidationSavings.toStringAsFixed(2)}',
    walletBalance: '\$${walletBalance.toStringAsFixed(2)} Available',
    subtotal: '\$${subtotal.toStringAsFixed(2)}',
    shipping: '\$${shipping.toStringAsFixed(2)}',
    insurance: '\$${insurance.toStringAsFixed(2)}',
    total: '\$${total > 0 ? total.toStringAsFixed(2) : '0.00'}',
    shipments: shipments,
  );
}

/// Checkout review built from cart. When backend is ready, use GET /api/checkout/review.
final checkoutReviewProvider = Provider<CheckoutReviewModel>((ref) {
  final cartItems = ref.watch(cartItemsProvider);
  return _buildReviewFromCart(cartItems);
});

/// Toggle wallet balance usage. API: include in POST /api/checkout/confirm later.
final checkoutWalletEnabledProvider = StateProvider<bool>((ref) => true);
