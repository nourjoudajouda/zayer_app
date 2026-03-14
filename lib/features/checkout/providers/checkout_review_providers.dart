import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/checkout_review_model.dart';
import '../models/payment_start_response.dart';

Future<String> _getPrimaryAddressShort(Ref ref) async {
  try {
    final profile = await ref.read(userProfileProvider.future);
    if (profile.primaryAddress.trim().isNotEmpty) return profile.primaryAddress;
  } catch (_) {}
  try {
    final addresses = await ref.read(addressesProvider.future);
    final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
    if (defaultAddr != null && defaultAddr.addressLine.trim().isNotEmpty) {
      return defaultAddr.addressLine;
    }
    if (addresses.isNotEmpty && addresses.first.addressLine.trim().isNotEmpty) {
      return addresses.first.addressLine;
    }
  } catch (_) {}
  return 'No address set';
}

/// Builds review from current cart. Replace with GET /api/checkout/review later.
CheckoutReviewModel _buildReviewFromCart(List<CartItem> cartItems, String primaryAddressShort) {
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
    shippingAddressShort: primaryAddressShort,
    consolidationSavings: '\$${consolidationSavings.toStringAsFixed(2)}',
    walletBalance: '\$${walletBalance.toStringAsFixed(2)} Available',
    subtotal: '\$${subtotal.toStringAsFixed(2)}',
    shipping: '\$${shipping.toStringAsFixed(2)}',
    insurance: '\$${insurance.toStringAsFixed(2)}',
    total: '\$${total > 0 ? total.toStringAsFixed(2) : '0.00'}',
    shipments: shipments,
  );
}

/// Checkout review from API: GET /api/checkout/review. Fallback to cart-built. Uses profile/addresses for shipping address when API omits it.
final checkoutReviewProvider = FutureProvider<CheckoutReviewModel>((ref) async {
  final addressFallback = _getPrimaryAddressShort(ref);
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/checkout/review');
    if (res.data != null) {
      final data = Map<String, dynamic>.from(res.data!);
      final short = (data['shipping_address_short'] ?? '').toString().trim();
      if (short.isEmpty) data['shipping_address_short'] = await addressFallback;
      return CheckoutReviewModel.fromJson(data);
    }
  } catch (_) {}
  final cartItems = ref.watch(cartItemsProvider);
  return _buildReviewFromCart(cartItems, await addressFallback);
});

/// Toggle wallet balance usage. Include in POST /api/checkout/confirm.
final checkoutWalletEnabledProvider = StateProvider<bool>((ref) => true);

/// Confirm checkout: POST /api/checkout/confirm
Future<({bool ok, String? orderId, String? orderNumber})> confirmCheckout(WidgetRef ref, {bool useWallet = true}) async {
  try {
    final res = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/checkout/confirm',
      data: {'use_wallet_balance': useWallet},
    );
    if (res.statusCode == 201 && res.data != null) {
      return (
        ok: true,
        orderId: res.data!['order_id']?.toString(),
        orderNumber: res.data!['order_number']?.toString(),
      );
    }
  } catch (_) {}
  return (ok: false, orderId: null, orderNumber: null);
}

/// Result of starting payment: either success with [checkoutUrl] or failure with [error].
typedef StartPaymentResult = ({String? checkoutUrl, String? error});

/// Start payment for an order: POST /api/orders/{orderId}/pay.
/// Returns checkout_url to open in WebView, or an error message.
Future<StartPaymentResult> startOrderPayment(String orderId) async {
  if (orderId.trim().isEmpty) {
    return (checkoutUrl: null, error: 'Invalid order');
  }
  try {
    final res = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/orders/$orderId/pay',
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      return (checkoutUrl: null, error: _messageFromResponse(res.data));
    }
    final data = res.data;
    if (data == null) {
      return (checkoutUrl: null, error: 'Invalid response');
    }
    final payment = PaymentStartResponse.fromJson(Map<String, dynamic>.from(data));
    final url = payment.checkoutUrl?.trim();
    if (url == null || url.isEmpty) {
      return (checkoutUrl: null, error: 'No payment link received');
    }
    return (checkoutUrl: url, error: null);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      return (checkoutUrl: null, error: 'Please sign in to pay');
    }
    final msg = _messageFromResponse(e.response?.data);
    if (msg.isNotEmpty) return (checkoutUrl: null, error: msg);
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return (checkoutUrl: null, error: 'Connection error. Check your network.');
    }
    return (checkoutUrl: null, error: 'Could not start payment');
  } catch (_) {
    return (checkoutUrl: null, error: 'Could not start payment');
  }
}

String _messageFromResponse(dynamic data) {
  if (data == null) return '';
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final values = errors.values.toList();
      if (values.isNotEmpty) {
        final first = values.first;
        if (first is List && first.isNotEmpty && first.first is String) {
          return first.first as String;
        }
      }
    }
  }
  return '';
}
