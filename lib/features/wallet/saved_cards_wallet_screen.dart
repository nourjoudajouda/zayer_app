import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
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
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCard() async {
    try {
      final setup = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards/setup-intent',
      );
      final secret =
          setup.data?['setup_intent']?['client_secret'] as String?;
      if (secret == null || secret.isEmpty) throw Exception('No setup intent');

      if (!mounted) return;

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppConfig.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _AddStripeCardSheet(clientSecret: secret),
      );
      if (confirmed != true || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            r'Check your bank for the verification amount ($1.00–$5.00), then tap Verify on the card.',
          ),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _verify(Map<String, dynamic> card) async {
    final id = card['id']?.toString();
    if (id == null) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verification amount'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Exact USD amount charged',
            hintText: 'e.g. 3.47',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify')),
        ],
      ),
    );
    if (ok != true) return;
    final amt = double.tryParse(ctrl.text.trim());
    ctrl.dispose();
    if (amt == null) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards/$id/verify',
        data: {'amount': amt},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card verified. Amount added to wallet.')),
      );
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
      await _reload();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Verify failed')
          : 'Verify failed';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    if (ok != true) return;
    final amt = double.tryParse(ctrl.text.trim());
    ctrl.dispose();
    if (amt == null || amt < 1) return;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
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
                        child: ListTile(
                          title: Text('$brand •••• $last4${def ? ' (default)' : ''}'),
                          subtitle: Text(status),
                          isThreeLine: true,
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
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddStripeCardSheet extends StatefulWidget {
  const _AddStripeCardSheet({required this.clientSecret});

  final String clientSecret;

  @override
  State<_AddStripeCardSheet> createState() => _AddStripeCardSheetState();
}

class _AddStripeCardSheetState extends State<_AddStripeCardSheet> {
  bool _cardComplete = false;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final si = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: widget.clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      final complete = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards',
        data: {'setup_intent_id': si.id},
      );

      final ver = complete.data?['verification'] as Map<String, dynamic>?;
      final cs = ver?['client_secret'] as String?;
      if (ver?['requires_action'] == true && cs != null && cs.isNotEmpty) {
        await Stripe.instance.handleNextAction(cs);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.error.message ?? 'Stripe error')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              setState(() => _cardComplete = card?.complete == true);
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
        ],
      ),
    );
  }
}
