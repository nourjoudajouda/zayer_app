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

/// Duplicate client [confirmPayment] after the server already confirmed the PI.
bool isPaymentIntentAlreadySucceededError(StripeException e) {
  final msg = (e.error.message ?? '').toLowerCase();
  final loc = (e.error.localizedMessage ?? '').toLowerCase();
  return msg.contains('already succeeded') || loc.contains('already succeeded');
}

/// Laravel creates saved-card top-up PaymentIntents with `confirm: true`, so the
/// PaymentIntent is often already [PaymentIntentsStatus.Succeeded] when this runs.
/// This must **not** call [Stripe.instance.confirmPayment] in that case (would error).
///
/// For [requires_action], uses [Stripe.instance.handleNextAction]. For the rare
/// [RequiresConfirmation], calls [confirmPayment] once.
Future<void> runSavedCardTopUpStripeClientStep({
  required String clientSecret,
  String? serverReportedStatus,
}) async {
  final fast = serverReportedStatus?.toLowerCase().trim();
  if (fast == 'succeeded' || fast == 'processing') {
    return;
  }

  PaymentIntent pi = await Stripe.instance.retrievePaymentIntent(clientSecret);

  for (var attempt = 0; attempt < 6; attempt++) {
    if (pi.status == PaymentIntentsStatus.Succeeded ||
        pi.status == PaymentIntentsStatus.Processing) {
      return;
    }
    if (pi.status == PaymentIntentsStatus.RequiresAction) {
      pi = await Stripe.instance.handleNextAction(clientSecret);
      continue;
    }
    if (pi.status == PaymentIntentsStatus.RequiresConfirmation) {
      try {
        pi = await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
        );
      } on StripeException catch (e) {
        if (isPaymentIntentAlreadySucceededError(e)) {
          return;
        }
        rethrow;
      }
      continue;
    }
    throw Exception(
      'The payment could not be completed. Try again or use another card.',
    );
  }

  if (pi.status == PaymentIntentsStatus.Succeeded ||
      pi.status == PaymentIntentsStatus.Processing) {
    return;
  }
  throw Exception(
    'The payment could not be completed. Try again or use another card.',
  );
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
