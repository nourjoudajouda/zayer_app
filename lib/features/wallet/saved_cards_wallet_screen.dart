import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'add_saved_card_screen.dart';
import 'providers/wallet_providers.dart';
import 'stripe_wallet_helpers.dart';

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
  /// POST /saved-cards/setup-intent only (brief). Never true while card sheet is open.
  bool _setupIntentLoading = false;
  /// Saved-card wallet top-up (Stripe PaymentIntent) only.
  bool _topUpInProgress = false;
  /// Prevents overlapping top-up requests before [setState] disables the button.
  bool _topUpActionLock = false;
  String? _error;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapStripe());
  }

  Future<void> _bootstrapStripe() async {
    final cfg = ref.read(bootstrapConfigProvider).valueOrNull;
    await ensureStripeInitializedFromBootstrap(cfg);
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
    if (_loading || _setupIntentLoading || _topUpInProgress) return;

    setState(() => _setupIntentLoading = true);
    String? secret;
    String? intentId;
    try {
      final cfg = await ref.read(bootstrapConfigProvider.future);
      final stripeOk = await ensureStripeInitializedFromBootstrap(cfg);
      if (!stripeOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Card payments are not configured yet. Pull to refresh or try again later.',
            ),
          ),
        );
        return;
      }

      savedCardFlowLog('create_setup_intent', 'request');
      final setup = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards/setup-intent',
      );
      final siMap = setup.data?['setup_intent'] as Map<String, dynamic>?;
      secret = siMap?['client_secret'] as String?;
      intentId = siMap?['setup_intent_id'] as String?;
      if (secret == null || secret.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Card setup could not be started. Check your connection and try again.',
            ),
          ),
        );
        return;
      }

      savedCardFlowLog('create_setup_intent', 'ok id=${intentId ?? "?"}');
    } catch (e) {
      savedCardFlowLog('create_setup_intent', 'error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingApiMessage(e))),
      );
      return;
    } finally {
      if (mounted) setState(() => _setupIntentLoading = false);
    }

    if (!mounted) return;

    final confirmed = await context.push<bool>(
      AppRoutes.walletAddSavedCard,
      extra: AddSavedCardRouteArgs(
        clientSecret: secret,
        setupIntentId: intentId,
      ),
    );
    if (confirmed != true || !mounted) return;

    // Defer list reload + dialog until after the add-card route has finished popping
    // so the Stripe [CardField] is not torn down while the parent rebuilds (avoids
    // `_dependents.isEmpty` / inherited-widget assertions).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingApiMessage(e))),
        );
      }
    });
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
                            savedCardFlowLog('verify_card_charge', 'POST amount=$amt id=$id');
                            await ApiClient.instance.post<Map<String, dynamic>>(
                              '/api/wallet/saved-cards/$id/verify',
                              data: {'amount': amt},
                            );
                            savedCardFlowLog('verify_card_charge', 'ok');
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
                            savedCardFlowLog('verify_card_charge', 'error: $e');
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
    if (_topUpActionLock || _topUpInProgress) return;
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

    _topUpActionLock = true;
    setState(() => _topUpInProgress = true);
    try {
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/top-up-saved-card',
        data: {'amount': amt, 'saved_payment_method_id': id},
      );
      final piRaw = res.data?['payment_intent'];
      final piMap = piRaw is Map<String, dynamic> ? piRaw : null;
      final secret = piMap?['client_secret'] as String?;
      final serverStatus = piMap?['status'] as String?;
      if (secret == null || secret.isEmpty) {
        throw Exception('Invalid payment response from server.');
      }

      await runSavedCardTopUpStripeClientStep(
        clientSecret: secret,
        serverReportedStatus: serverStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted. Your wallet will update shortly.'),
        ),
      );
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
    } on StripeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_savedCardTopUpStripeUserMessage(e)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingApiMessage(e))),
      );
    } finally {
      _topUpActionLock = false;
      if (mounted) setState(() => _topUpInProgress = false);
    }
  }

  String _savedCardTopUpStripeUserMessage(StripeException e) {
    if (isPaymentIntentAlreadySucceededError(e)) {
      return 'This payment was already completed. Your balance will update shortly.';
    }
    final t = e.error.localizedMessage ?? e.error.message;
    if (t == null || t.trim().isEmpty) {
      return 'Payment could not be completed. Please try again.';
    }
    return t;
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
          if (_setupIntentLoading || _topUpInProgress)
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
        onPressed: (_loading || _setupIntentLoading || _topUpInProgress)
            ? null
            : _addCard,
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
                                    onPressed: (_topUpInProgress || _setupIntentLoading)
                                        ? null
                                        : () => _verify(c),
                                    child: const Text('Verify'),
                                  )
                                : status == 'verified'
                                    ? TextButton(
                                        onPressed: _topUpInProgress
                                            ? null
                                            : () => _topUp(c),
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
