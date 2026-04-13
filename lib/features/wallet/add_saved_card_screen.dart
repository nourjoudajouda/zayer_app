import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart' show userFacingApiMessage;
import '../../core/theme/app_spacing.dart';
import 'stripe_wallet_helpers.dart';

/// Arguments for [AddSavedCardScreen] (pass via `GoRouter` extra).
class AddSavedCardRouteArgs {
  const AddSavedCardRouteArgs({
    required this.clientSecret,
    this.setupIntentId,
  });

  final String clientSecret;
  final String? setupIntentId;
}

/// Full-screen card entry: avoids Android touch/focus issues with Stripe
/// platform views inside modal bottom sheets.
///
/// Flow: confirm SetupIntent → POST saved-cards → optional PI 3DS → pop(true).
class AddSavedCardScreen extends ConsumerStatefulWidget {
  const AddSavedCardScreen({super.key, required this.args});

  final AddSavedCardRouteArgs args;

  @override
  ConsumerState<AddSavedCardScreen> createState() => _AddSavedCardScreenState();
}

class _AddSavedCardScreenState extends ConsumerState<AddSavedCardScreen> {
  bool _cardComplete = false;
  bool _submitting = false;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cfg = ref.read(bootstrapConfigProvider).valueOrNull;
      applyStripePublishableKey(cfg);
      try {
        await Stripe.instance.applySettings();
      } catch (_) {}
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _pageError = null;
    });
    try {
      savedCardFlowLog(
        'confirm_setup_intent',
        'start setupIntentId=${widget.args.setupIntentId ?? "?"}',
      );

      var si = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: widget.args.clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      savedCardFlowLog('confirm_setup_intent', 'status=${si.status}');

      var actionAttempts = 0;
      while (setupIntentStatusRequiresAction(si.status) && actionAttempts < 5) {
        actionAttempts++;
        savedCardFlowLog(
          'confirm_setup_intent',
          'handleNextActionForSetupIntent attempt $actionAttempts',
        );
        si = await Stripe.instance.handleNextActionForSetupIntent(
          widget.args.clientSecret,
        );
        savedCardFlowLog('confirm_setup_intent', 'status=${si.status}');
      }

      if (!setupIntentStatusSucceeded(si.status)) {
        savedCardFlowLog(
          'confirm_setup_intent',
          'aborted: not succeeded (${si.status})',
        );
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _pageError =
              'Card setup did not finish. Complete any bank prompts, or try another card.';
        });
        return;
      }

      savedCardFlowLog('save_card_backend', 'POST setup_intent_id=${si.id}');
      final complete = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards',
        data: {'setup_intent_id': si.id},
      );

      final ver = complete.data?['verification'] as Map<String, dynamic>?;
      final cs = ver?['client_secret'] as String?;
      final needsAction = ver?['requires_action'] == true;
      if (needsAction && cs != null && cs.isNotEmpty) {
        savedCardFlowLog('verify_card_charge', 'handleNextAction (PI)');
        final pi = await Stripe.instance.handleNextAction(cs);
        if (pi.status != PaymentIntentsStatus.Succeeded) {
          savedCardFlowLog(
            'verify_card_charge',
            'PI not succeeded: ${pi.status}',
          );
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _pageError =
                'The verification charge could not be completed. Try again or use another card.';
          });
          return;
        }
      }

      savedCardFlowLog('save_card_backend', 'complete');
      if (!mounted) return;
      context.pop(true);
    } on StripeException catch (e) {
      savedCardFlowLog(
        'confirm_setup_intent',
        'StripeException: ${e.error.message}',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _pageError =
            e.error.message ?? 'Card could not be saved. Please try again.';
      });
    } catch (e) {
      savedCardFlowLog('save_card_backend', 'error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _pageError = userFacingApiMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formStyle = CardFormStyle(
      backgroundColor: AppConfig.lightBlueBg,
      borderColor: AppConfig.borderColor,
      borderWidth: 1,
      borderRadius: AppConfig.radiusSmall.round(),
      cursorColor: AppConfig.primaryColor,
      textColor: AppConfig.textColor,
      fontSize: 16,
      placeholderColor: AppConfig.subtitleColor,
    );

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Add a card'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Debit or credit card',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your card details securely. After you save, we charge a small '
                r'amount ($1.00–$5.00) so you can verify it from your bank statement.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppConfig.subtitleColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Card details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
              ),
              const SizedBox(height: 10),
              CardFormField(
                autofocus: true,
                enablePostalCode: false,
                style: formStyle,
                onCardChanged: (card) {
                  setState(() {
                    _cardComplete = card?.complete == true;
                    _pageError = null;
                  });
                },
              ),
              if (_pageError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _pageError!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: (!_cardComplete || _submitting) ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Save card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
