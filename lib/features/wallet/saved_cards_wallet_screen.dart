import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_providers.dart';
import 'stripe_wallet_helpers.dart';

void _savedCardFlowLog(String step, [String? detail]) {
  if (kDebugMode) {
    debugPrint('[saved_card_flow] $step${detail != null ? ': $detail' : ''}');
  }
}

bool _setupIntentStatusSucceeded(String status) =>
    status.toLowerCase() == 'succeeded';

bool _setupIntentStatusRequiresAction(String status) =>
    status.toLowerCase() == 'requires_action';

/// Saved cards: add via Stripe SetupIntent, verify micro-charge, top up with PaymentIntent.
class SavedCardsWalletScreen extends ConsumerStatefulWidget {
  const SavedCardsWalletScreen({super.key, this.initialTopUpAmount});

  final double? initialTopUpAmount;

  @override
  ConsumerState<SavedCardsWalletScreen> createState() =>
      _SavedCardsWalletScreenState();
}

class _SavedCardsWalletScreenState extends ConsumerState<SavedCardsWalletScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapStripe());
  }

  Future<void> _bootstrapStripe() async {
    final cfg = ref.read(bootstrapConfigProvider).valueOrNull;
    applyStripePublishableKey(cfg);
    try {
      await Stripe.instance.applySettings();
    } catch (_) {}
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/wallet/saved-cards',
      );
      final list = res.data?['saved_payment_methods'];
      _cards = list is List
          ? list.whereType<Map<String, dynamic>>().toList()
          : [];
    } catch (e) {
      _error = userFacingApiMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCard() async {
    setState(() => _busy = true);
    try {
      _savedCardFlowLog('create_setup_intent', 'request');
      final setup = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards/setup-intent',
      );
      final siMap = setup.data?['setup_intent'] as Map<String, dynamic>?;
      final secret = siMap?['client_secret'] as String?;
      final intentId = siMap?['setup_intent_id'] as String?;
      if (secret == null || secret.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start card setup. Please try again.'),
          ),
        );
        return;
      }

      _savedCardFlowLog('create_setup_intent', 'ok id=${intentId ?? "?"}');

      if (!mounted) return;

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppConfig.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _AddStripeCardSheet(
          clientSecret: secret,
          setupIntentId: intentId,
        ),
      );
      if (confirmed != true || !mounted) return;

      await _reload();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify your card'),
          content: const Text(
            'We placed a small random charge on your card between \$1.00 and \$5.00 USD '
            'to confirm you own it.\n\n'
            'Check your bank app or card statement for the exact amount, then return here '
            'and tap Verify on this card and enter that amount. The same amount will be '
            'credited to your wallet when verification succeeds.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _savedCardFlowLog('create_setup_intent', 'error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingApiMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(Map<String, dynamic> card) async {
    final id = card['id']?.toString();
    if (id == null) return;
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? fieldError;
        var submitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Verification amount'),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setDialogState(() => fieldError = null),
                decoration: InputDecoration(
                  labelText: 'Exact USD amount charged',
                  hintText: 'e.g. 3.47',
                  helperText: r'Must be between $1.00 and $5.00',
                  errorText: fieldError,
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final raw = ctrl.text.trim();
                          final amt = double.tryParse(raw);
                          if (amt == null) {
                            setDialogState(
                              () => fieldError =
                                  'Enter the exact amount from your bank.',
                            );
                            return;
                          }
                          if (amt < 1 || amt > 5) {
                            setDialogState(
                              () => fieldError =
                                  r'Enter an amount between $1.00 and $5.00.',
                            );
                            return;
                          }
                          setDialogState(() {
                            submitting = true;
                            fieldError = null;
                          });
                          try {
                            _savedCardFlowLog('verify_card_charge', 'POST amount=$amt id=$id');
                            await ApiClient.instance.post<Map<String, dynamic>>(
                              '/api/wallet/saved-cards/$id/verify',
                              data: {'amount': amt},
                            );
                            _savedCardFlowLog('verify_card_charge', 'ok');
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Card verified. Amount added to wallet.',
                                ),
                              ),
                            );
                            ref.invalidate(walletBalanceProvider);
                            ref.invalidate(walletTransactionsProvider);
                            await _reload();
                          } catch (e) {
                            _savedCardFlowLog('verify_card_charge', 'error: $e');
                            final errs = validationErrorsFromDio(e);
                            setDialogState(() {
                              submitting = false;
                              fieldError = errs['amount'] ??
                                  userFacingApiMessage(e);
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(ctrl.dispose);
  }

  Future<void> _topUp(Map<String, dynamic> card) async {
    final id = int.tryParse(card['id']?.toString() ?? '');
    if (id == null) return;
    final ctrl = TextEditingController(
      text: widget.initialTopUpAmount?.toStringAsFixed(2) ?? '50.00',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top up wallet'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount USD'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    final raw = ctrl.text.trim();
    ctrl.dispose();
    final amt = double.tryParse(raw);
    if (amt == null || amt < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount of at least \$1.00.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/top-up-saved-card',
        data: {'amount': amt, 'saved_payment_method_id': id},
      );
      final secret =
          res.data?['payment_intent']?['client_secret'] as String?;
      if (secret == null || secret.isEmpty) throw Exception('No client secret');

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: secret,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment submitted. Your wallet will update shortly.')),
      );
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
    } on StripeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.error.message ?? 'Payment failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingApiMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _cardStatusLabel(String status) {
    switch (status) {
      case 'pending_verification':
        return 'Pending verification';
      case 'verified':
        return 'Verified';
      case 'failed_verification':
        return 'Verification failed';
      case 'disabled':
        return 'Disabled';
      default:
        return status;
    }
  }

  static Color _cardStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppConfig.successGreen;
      case 'failed_verification':
        return Colors.red.shade700;
      case 'pending_verification':
        return AppConfig.warningOrange;
      default:
        return AppConfig.subtitleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Cards'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_busy || _loading) ? null : _addCard,
        icon: const Icon(Icons.add),
        label: const Text('Add card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _cards.length,
                    itemBuilder: (context, i) {
                      final c = _cards[i];
                      final status = c['verification_status']?.toString() ?? '';
                      final last4 = c['last4']?.toString() ?? '????';
                      final brand = c['brand']?.toString() ?? 'Card';
                      final def = c['is_default'] == true;
                      return Card(
                        color: AppConfig.cardColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              '$brand •••• $last4${def ? ' (default)' : ''}',
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        label: Text(
                                          _cardStatusLabel(status),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: _cardStatusColor(status)
                                            .withValues(alpha: 0.15),
                                        side: BorderSide(
                                          color: _cardStatusColor(status)
                                              .withValues(alpha: 0.35),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (status == 'failed_verification')
                                        Text(
                                          'Remove the card and add it again, or contact support.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppConfig.subtitleColor,
                                              ),
                                        ),
                                    ],
                                  ),
                                  if (status == 'pending_verification') ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      r'Look for a $1.00–$5.00 charge on your statement, '
                                      r'then tap Verify and enter the exact amount.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppConfig.subtitleColor,
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            isThreeLine: status == 'failed_verification' ||
                                status == 'pending_verification',
                            trailing: status == 'pending_verification'
                                ? TextButton(
                                    onPressed: _busy ? null : () => _verify(c),
                                    child: const Text('Verify'),
                                  )
                                : status == 'verified'
                                    ? TextButton(
                                        onPressed: _busy ? null : () => _topUp(c),
                                        child: const Text('Top up'),
                                      )
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddStripeCardSheet extends StatefulWidget {
  const _AddStripeCardSheet({
    required this.clientSecret,
    this.setupIntentId,
  });

  final String clientSecret;
  final String? setupIntentId;

  @override
  State<_AddStripeCardSheet> createState() => _AddStripeCardSheetState();
}

class _AddStripeCardSheetState extends State<_AddStripeCardSheet> {
  bool _cardComplete = false;
  bool _submitting = false;
  String? _sheetError;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _sheetError = null;
    });
    try {
      _savedCardFlowLog(
        'confirm_setup_intent',
        'start setupIntentId=${widget.setupIntentId ?? "?"}',
      );

      var si = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: widget.clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      _savedCardFlowLog('confirm_setup_intent', 'status=${si.status}');

      var actionAttempts = 0;
      while (_setupIntentStatusRequiresAction(si.status) && actionAttempts < 5) {
        actionAttempts++;
        _savedCardFlowLog(
          'confirm_setup_intent',
          'handleNextActionForSetupIntent attempt $actionAttempts',
        );
        si = await Stripe.instance.handleNextActionForSetupIntent(
          widget.clientSecret,
        );
        _savedCardFlowLog('confirm_setup_intent', 'status=${si.status}');
      }

      if (!_setupIntentStatusSucceeded(si.status)) {
        _savedCardFlowLog(
          'confirm_setup_intent',
          'aborted: not succeeded (${si.status})',
        );
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _sheetError =
              'Card setup did not finish. Complete any bank prompts, or try another card.';
        });
        return;
      }

      _savedCardFlowLog('save_card_backend', 'POST setup_intent_id=${si.id}');
      final complete = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards',
        data: {'setup_intent_id': si.id},
      );

      final ver = complete.data?['verification'] as Map<String, dynamic>?;
      final cs = ver?['client_secret'] as String?;
      final needsAction = ver?['requires_action'] == true;
      if (needsAction && cs != null && cs.isNotEmpty) {
        _savedCardFlowLog('verify_card_charge', 'handleNextAction (PI)');
        final pi = await Stripe.instance.handleNextAction(cs);
        if (pi.status != PaymentIntentsStatus.Succeeded) {
          _savedCardFlowLog(
            'verify_card_charge',
            'PI not succeeded: ${pi.status}',
          );
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _sheetError =
                'The verification charge could not be completed. Try again or use another card.';
          });
          return;
        }
      }

      _savedCardFlowLog('save_card_backend', 'complete');
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      _savedCardFlowLog('confirm_setup_intent', 'StripeException: ${e.error.message}');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sheetError =
            e.error.message ?? 'Card could not be saved. Please try again.';
      });
    } catch (e) {
      _savedCardFlowLog('save_card_backend', 'error: $e');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sheetError = userFacingApiMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context).bottom;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: pad + inset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add card',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          CardField(
            onCardChanged: (card) {
              setState(() {
                _cardComplete = card?.complete == true;
                _sheetError = null;
              });
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (!_cardComplete || _submitting) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save & verify'),
          ),
          if (_sheetError != null) ...[
            const SizedBox(height: 12),
            Text(
              _sheetError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
