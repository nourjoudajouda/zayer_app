import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../core/config/models/app_bootstrap_config.dart';

/// Debug-only logging for saved-card SetupIntent / verify flows.
void savedCardFlowLog(String step, [String? detail]) {
  if (kDebugMode) {
    debugPrint('[saved_card_flow] $step${detail != null ? ': $detail' : ''}');
  }
}

bool setupIntentStatusSucceeded(String status) =>
    status.toLowerCase() == 'succeeded';

bool setupIntentStatusRequiresAction(String status) =>
    status.toLowerCase() == 'requires_action';

/// Applies Stripe publishable key from bootstrap (required before CardField / confirmations).
void applyStripePublishableKey(AppBootstrapConfig? config) {
  final pk = config?.paymentGateways?.providers['stripe']?.publishableKey;
  if (pk != null && pk.trim().isNotEmpty) {
    Stripe.publishableKey = pk.trim();
  }
}

bool stripeEnabledInBootstrap(AppBootstrapConfig? config) {
  final pg = config?.paymentGateways;
  if (pg == null) return false;
  return pg.enabled.contains('stripe') &&
      (pg.providers['stripe']?.enabled ?? false);
}
