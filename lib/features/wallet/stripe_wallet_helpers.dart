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

/// True when [StripeException] from [Stripe.instance.confirmSetupIntent] indicates the
/// SetupIntent is no longer confirmable because it already completed (e.g. duplicate confirm).
bool isSetupIntentAlreadySucceededError(StripeException e) {
  final msg = (e.error.message ?? '').toLowerCase();
  final loc = (e.error.localizedMessage ?? '').toLowerCase();
  final stripeCode = (e.error.stripeErrorCode ?? '').toLowerCase();
  return msg.contains('already succeeded') ||
      loc.contains('already succeeded') ||
      stripeCode == 'setup_intent_unexpected_state';
}

/// Resolves Stripe publishable key: nested `payment_gateways.providers.stripe` first,
/// then root-level [AppBootstrapConfig.stripePublishableKey] (e.g. `stripe_publishable_key`).
String? resolveStripePublishableKey(AppBootstrapConfig? config) {
  if (config == null) return null;
  final nested = config.paymentGateways?.providers['stripe']?.publishableKey;
  if (nested != null && nested.trim().isNotEmpty) return nested.trim();
  final root = config.stripePublishableKey;
  if (root != null && root.trim().isNotEmpty) return root.trim();
  return null;
}

/// Applies Stripe publishable key from bootstrap (required before CardField / confirmations).
void applyStripePublishableKey(AppBootstrapConfig? config) {
  final pk = resolveStripePublishableKey(config);
  if (pk != null && pk.isNotEmpty) {
    Stripe.publishableKey = pk;
  }
}

/// Sets [Stripe.publishableKey], then [Stripe.instance.applySettings]. Returns false if no key or apply fails.
Future<bool> ensureStripeInitializedFromBootstrap(AppBootstrapConfig? config) async {
  applyStripePublishableKey(config);
  final pk = resolveStripePublishableKey(config);
  if (pk == null || pk.isEmpty) return false;
  try {
    await Stripe.instance.applySettings();
    return true;
  } catch (_) {
    return false;
  }
}

bool stripeEnabledInBootstrap(AppBootstrapConfig? config) {
  final pg = config?.paymentGateways;
  if (pg == null) return false;
  return pg.enabled.contains('stripe') &&
      (pg.providers['stripe']?.enabled ?? false);
}
