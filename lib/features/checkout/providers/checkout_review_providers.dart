import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checkout_review_model.dart';

/// Mock checkout review. Replace with GET /api/checkout/review later.
Future<CheckoutReviewModel> _fetchReview() async {
  await Future.delayed(const Duration(milliseconds: 350));
  return const CheckoutReviewModel(
    shipments: [
      CheckoutShipment(
        originLabel: 'USA Shipment',
        items: [
          CheckoutShipmentItem(
            name: 'Wireless Earbuds Pro',
            price: '\$89.99',
            quantity: 1,
            eta: 'Dec 2–5, 2024',
          ),
        ],
      ),
      CheckoutShipment(
        originLabel: 'Turkey Shipment',
        items: [
          CheckoutShipmentItem(
            name: 'Leather Crossbody Bag',
            price: '\$65.00',
            quantity: 2,
            eta: 'Dec 8–12, 2024',
          ),
        ],
      ),
    ],
  );
}

final checkoutReviewProvider =
    FutureProvider<CheckoutReviewModel>((ref) => _fetchReview());

/// Toggle wallet balance usage. API: include in POST /api/checkout/confirm later.
final checkoutWalletEnabledProvider = StateProvider<bool>((ref) => true);
