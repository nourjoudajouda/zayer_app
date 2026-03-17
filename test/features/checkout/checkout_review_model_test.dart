import 'package:flutter_test/flutter_test.dart';
import 'package:zayer_app/features/checkout/models/checkout_review_model.dart';

void main() {
  group('CheckoutReviewModel', () {
    test('parses amount_due_now as num', () {
      final m = CheckoutReviewModel.fromJson({
        'shipments': [],
        'amount_due_now': 12.34,
      });
      expect(m.amountDueNow, 12.34);
    });

    test('parses amount_due_now as string money', () {
      final m = CheckoutReviewModel.fromJson({
        'shipments': [],
        'amount_due_now': r'$56.78',
      });
      expect(m.amountDueNow, 56.78);
    });

    test('parses wallet_applied as string', () {
      final m = CheckoutReviewModel.fromJson({
        'shipments': [],
        'wallet_applied': r'-$10.00',
      });
      expect(m.walletApplied, -10.0);
    });
  });
}

