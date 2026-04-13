import 'package:flutter_stripe/flutter_stripe.dart';

import '../../core/config/models/app_bootstrap_config.dart';

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
