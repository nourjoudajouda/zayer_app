import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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

/// Checkout review from API: GET /api/checkout/review.
/// Backend is the source of truth for pricing/shipping; payment method is chosen explicitly at confirm.
final checkoutPromoCodeProvider = StateProvider<String>((ref) => '');

final checkoutReviewProvider = FutureProvider<CheckoutReviewModel>((ref) async {
  final addressFallback = await _getPrimaryAddressShort(ref);
  final promoCode = ref.watch(checkoutPromoCodeProvider).trim();
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/checkout/review',
    queryParameters: promoCode.isEmpty ? null : {'promo_code': promoCode},
  );
  final raw = res.data;
  if (raw == null) {
    throw Exception('Empty checkout review response');
  }
  final data = Map<String, dynamic>.from(raw);
  final short = (data['shipping_address_short'] ?? '').toString().trim();
  if (short.isEmpty) data['shipping_address_short'] = addressFallback;
  return CheckoutReviewModel.fromJson(data);
});

/// User override for payment method (`wallet` | `gateway`). Null = use default from [CheckoutReviewModel.checkoutPaymentMode].
final checkoutPaymentMethodSelectionProvider = StateProvider<String?>((ref) => null);

/// Confirm checkout: POST /api/checkout/confirm with `payment_method` + legacy `use_wallet_balance` when applicable.
Future<CheckoutConfirmResult> confirmCheckout(
  WidgetRef ref, {
  required String paymentMethod,
}) async {
  final promoCode = ref.read(checkoutPromoCodeProvider).trim();
  try {
    final res = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/checkout/confirm',
      data: {
        'payment_method': paymentMethod,
        'use_wallet_balance': paymentMethod == 'wallet',
        if (promoCode.isNotEmpty) 'promo_code': promoCode,
      },
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    final code = res.statusCode ?? 0;
    final data = res.data;
    if (code == 201 && data != null) {
      return CheckoutConfirmResult(
        ok: true,
        orderId: data['order_id']?.toString(),
        orderNumber: data['order_number']?.toString(),
      );
    }
    if (data is Map<String, dynamic>) {
      return CheckoutConfirmResult(
        ok: false,
        errorCode: data['error_code']?.toString(),
        message: data['message']?.toString(),
        errorBody: Map<String, dynamic>.from(data),
      );
    }
  } on DioException catch (e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return CheckoutConfirmResult(
        ok: false,
        errorCode: data['error_code']?.toString(),
        message: data['message']?.toString(),
        errorBody: Map<String, dynamic>.from(data),
      );
    }
  } catch (_) {}
  return const CheckoutConfirmResult(ok: false);
}

class CheckoutConfirmResult {
  const CheckoutConfirmResult({
    required this.ok,
    this.orderId,
    this.orderNumber,
    this.errorCode,
    this.message,
    this.errorBody,
  });

  final bool ok;
  final String? orderId;
  final String? orderNumber;
  final String? errorCode;
  final String? message;
  final Map<String, dynamic>? errorBody;
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
    final payload = (data['data'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(data['data'] as Map<String, dynamic>)
        : Map<String, dynamic>.from(data);
    final payment = PaymentStartResponse.fromJson(payload);
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
