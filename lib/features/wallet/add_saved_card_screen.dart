import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
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

/// Single-line [CardField] platform view needs a bounded height on Android inside
/// scrollables; allow room for [InputDecorator] + Stripe’s ~48dp row.
const double _kCardFieldShellHeight = 72;

/// Arguments for [AddSavedCardScreen] (pass via `GoRouter` extra).
class AddSavedCardRouteArgs {
  const AddSavedCardRouteArgs({
    required this.clientSecret,
    this.setupIntentId,
  });

  final String clientSecret;
  final String? setupIntentId;
}

/// Full-screen card entry using Stripe [CardField] (single secure platform view).
/// [CardFormField] was removed due to persistent blank rendering on Android in this app.
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
  /// Synchronous guard so two taps cannot start two confirms before the next frame.
  bool _submitLocked = false;
  String? _pageError;
  bool _stripeLoading = true;
  bool _stripeReady = false;

  @override
  void initState() {
    super.initState();
    _initStripe();
  }

  Future<void> _initStripe() async {
    try {
      final cfg = await ref.read(bootstrapConfigProvider.future);
      final ok = await ensureStripeInitializedFromBootstrap(cfg);
      if (!mounted) return;
      setState(() {
        _stripeLoading = false;
        _stripeReady = ok;
        if (!ok) {
          _pageError =
              'Card entry is unavailable because payment settings did not load. '
              'Go back and pull to refresh, then try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stripeLoading = false;
        _stripeReady = false;
        _pageError = userFacingApiMessage(e);
      });
    }
  }

  /// After Stripe and backend work, close the route on the next frame so the
  /// [CardField] platform view can detach before the widget subtree is torn down
  /// (avoids `InheritedWidget` / `_dependents` assertions during pop).
  void _schedulePopSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.pop(true);
    });
  }

  Future<SetupIntent?> _retrieveSucceededSetupIntent() async {
    try {
      final si =
          await Stripe.instance.retrieveSetupIntent(widget.args.clientSecret);
      if (setupIntentStatusSucceeded(si.status)) {
        return si;
      }
    } catch (e) {
      savedCardFlowLog('retrieve_setup_intent', 'error: $e');
    }
    return null;
  }

  /// Backend POST + optional verification PI 3DS, then one deferred pop on success.
  Future<bool> _completeAfterSetupIntentSucceeded(SetupIntent si) async {
    if (!setupIntentStatusSucceeded(si.status)) {
      savedCardFlowLog(
        'confirm_setup_intent',
        'aborted: not succeeded (${si.status})',
      );
      if (!mounted) return false;
      setState(() {
        _submitting = false;
        _pageError =
            'Card setup did not finish. Complete any bank prompts, or try another card.';
      });
      return false;
    }

    try {
      savedCardFlowLog('save_card_backend', 'POST setup_intent_id=${si.id}');
      final complete = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards',
        data: {'setup_intent_id': si.id},
      );

      if (!mounted) return false;

      final ver = complete.data?['verification'] as Map<String, dynamic>?;
      final cs = ver?['client_secret'] as String?;
      final needsAction = ver?['requires_action'] == true;
      if (needsAction && cs != null && cs.isNotEmpty) {
        savedCardFlowLog('verify_card_charge', 'handleNextAction (PI)');
        final pi = await Stripe.instance.handleNextAction(cs);
        if (!mounted) return false;
        if (pi.status != PaymentIntentsStatus.Succeeded) {
          savedCardFlowLog(
            'verify_card_charge',
            'PI not succeeded: ${pi.status}',
          );
          setState(() {
            _submitting = false;
            _pageError =
                'The verification charge could not be completed. Try again or use another card.';
          });
          return false;
        }
      }

      savedCardFlowLog('save_card_backend', 'complete');
      if (!mounted) return false;
      _schedulePopSuccess();
      return true;
    } catch (e) {
      savedCardFlowLog('save_card_backend', 'error: $e');
      if (!mounted) return false;
      setState(() {
        _submitting = false;
        _pageError = userFacingApiMessage(e);
      });
      return false;
    }
  }

  String _friendlyStripeConfirmError(StripeException e) {
    if (isSetupIntentAlreadySucceededError(e)) {
      return 'This card step was already completed. Go back and tap Add card again to use a new setup.';
    }
    final text = e.error.localizedMessage ?? e.error.message;
    if (text == null || text.trim().isEmpty) {
      return 'Card could not be saved. Please try again.';
    }
    return text;
  }

  Future<void> _submit() async {
    if (_submitLocked || _submitting) return;
    _submitLocked = true;
    if (!mounted) {
      _submitLocked = false;
      return;
    }
    setState(() {
      _submitting = true;
      _pageError = null;
    });

    try {
      savedCardFlowLog(
        'confirm_setup_intent',
        'start setupIntentId=${widget.args.setupIntentId ?? "?"}',
      );

      late SetupIntent si;
      try {
        si = await Stripe.instance.confirmSetupIntent(
          paymentIntentClientSecret: widget.args.clientSecret,
          params: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );
      } on StripeException catch (e) {
        if (isSetupIntentAlreadySucceededError(e)) {
          savedCardFlowLog(
            'confirm_setup_intent',
            'recover: already succeeded — retrieve SI',
          );
          final recovered = await _retrieveSucceededSetupIntent();
          if (!mounted) return;
          if (recovered == null) {
            setState(() {
              _submitting = false;
              _pageError =
                  'This card setup was already completed. Go back and try Add card again.';
            });
            return;
          }
          si = recovered;
        } else {
          rethrow;
        }
      }

      savedCardFlowLog('confirm_setup_intent', 'status=${si.status}');

      var actionAttempts = 0;
      while (setupIntentStatusRequiresAction(si.status) && actionAttempts < 5) {
        if (!mounted) return;
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

      await _completeAfterSetupIntentSucceeded(si);
    } on StripeException catch (e) {
      savedCardFlowLog(
        'confirm_setup_intent',
        'StripeException: ${e.error.message}',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _pageError = _friendlyStripeConfirmError(e);
      });
    } catch (e) {
      savedCardFlowLog('save_card_backend', 'error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _pageError = userFacingApiMessage(e);
      });
    } finally {
      _submitLocked = false;
    }
  }

  InputDecoration _cardFieldDecoration(ThemeData theme) {
    final radius = BorderRadius.circular(AppConfig.radiusSmall);
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppConfig.lightBlueBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppConfig.borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
      ),
      hintStyle: TextStyle(
        color: AppConfig.subtitleColor.withValues(alpha: 0.9),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final androidRender = defaultTargetPlatform == TargetPlatform.android
        ? AndroidPlatformViewRenderType.androidView
        : AndroidPlatformViewRenderType.expensiveAndroidView;

    if (_stripeLoading) {
      return Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: const Text('Add a card'),
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_stripeReady) {
      return Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: const Text('Add a card'),
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _pageError ??
                      'Card entry is unavailable. Go back and try again.',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(
                    color: AppConfig.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfig.textColor.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: _kCardFieldShellHeight,
                  width: double.infinity,
                  child: CardField(
                    autofocus: true,
                    androidPlatformViewRenderType: androidRender,
                    style: const TextStyle(
                      color: AppConfig.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: AppConfig.primaryColor,
                    decoration: _cardFieldDecoration(theme),
                    numberHintText: 'Card number',
                    expirationHintText: 'MM / YY',
                    cvcHintText: 'CVC',
                    onCardChanged: (card) {
                      if (!mounted) return;
                      setState(() {
                        _cardComplete = card?.complete == true;
                        _pageError = null;
                      });
                    },
                  ),
                ),
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
