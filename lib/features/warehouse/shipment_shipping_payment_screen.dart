import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../checkout/payment_webview_screen.dart';
import '../wallet/providers/wallet_providers.dart';
import 'models/warehouse_models.dart';
import 'warehouse_api.dart';

/// Second payment: shipping + fees only. Respects same checkout payment mode as cart checkout.
class ShipmentShippingPaymentScreen extends ConsumerStatefulWidget {
  const ShipmentShippingPaymentScreen({
    super.key,
    required this.shipmentId,
    required this.total,
    required this.breakdown,
    required this.shipment,
    this.checkoutPaymentMode,
  });

  final String shipmentId;
  final double total;
  final Map<String, dynamic> breakdown;
  final OutboundShipmentApi shipment;
  /// From POST /api/shipments/create; falls back to bootstrap [checkout_payment_mode].
  final String? checkoutPaymentMode;

  @override
  ConsumerState<ShipmentShippingPaymentScreen> createState() =>
      _ShipmentShippingPaymentScreenState();
}

class _ShipmentShippingPaymentScreenState
    extends ConsumerState<ShipmentShippingPaymentScreen> {
  bool _busy = false;
  /// Used when mode is `wallet_and_gateway`.
  String _walletGatewayChoice = 'gateway';

  String _resolveMode(String? fromRoute, String? fromBootstrap) {
    for (final c in [fromRoute, fromBootstrap]) {
      final m = c?.trim().toLowerCase();
      if (m != null &&
          m.isNotEmpty &&
          ['wallet_only', 'gateway_only', 'wallet_and_gateway'].contains(m)) {
        return m;
      }
    }
    return 'gateway_only';
  }

  String _effectivePaymentMethod(String mode) {
    switch (mode) {
      case 'wallet_only':
        return 'wallet';
      case 'gateway_only':
        return 'gateway';
      case 'wallet_and_gateway':
        return _walletGatewayChoice;
      default:
        return 'gateway';
    }
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (!didPop) return;
    if (widget.shipment.status.toLowerCase() != 'draft') return;
    try {
      await deleteShipmentDraft(widget.shipmentId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(bootstrapConfigProvider).valueOrNull;
    final mode = _resolveMode(widget.checkoutPaymentMode, boot?.checkoutPaymentMode);
    final walletAsync = ref.watch(walletBalanceProvider);
    final balance = walletAsync.valueOrNull?.available ?? 0.0;
    final payable = widget.total;
    final canWalletPay = payable <= 0.0001 || balance + 0.0001 >= payable;
    final shortage = (payable - balance) > 0 ? (payable - balance) : 0.0;
    final effective = _effectivePaymentMethod(mode);
    final showWallet = mode == 'wallet_only' || mode == 'wallet_and_gateway';
    final showGateway = mode == 'gateway_only' || mode == 'wallet_and_gateway';
    final gw = boot?.paymentGateways?.defaultGatewayCode;

    final ship = widget.breakdown['shipping_cost'];
    final add = widget.breakdown['additional_fees'];
    final shipStr = ship is num ? ship.toDouble().toStringAsFixed(2) : '—';
    final addStr = add is num ? add.toDouble().toStringAsFixed(2) : '—';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: const Text('Shipping payment'),
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'This payment is only for shipping and warehouse fees — not your original product order.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            _row('Shipping estimate', '\$$shipStr'),
            _row('Additional fees', '\$$addStr'),
            const Divider(height: AppSpacing.xl),
            _row('Total due', '\$${widget.total.toStringAsFixed(2)}', bold: true),
            if (showWallet) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Payment',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _row('Wallet balance', '\$${balance.toStringAsFixed(2)}'),
                    if (effective == 'wallet' && !canWalletPay && payable > 0.0001) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _row('Need to top up', '\$${shortage.toStringAsFixed(2)}', emphasize: true),
                    ],
                    if (mode == 'wallet_only') ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Checkout is configured for wallet payment only.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                      ),
                    ],
                    if (mode == 'gateway_only') ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Checkout is configured for card payment only.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                      ),
                    ],
                    if (mode == 'wallet_and_gateway') ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Choose how to pay',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppConfig.subtitleColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _methodTile(
                        selected: _walletGatewayChoice == 'wallet',
                        title: 'Wallet',
                        subtitle: canWalletPay ? 'Pay using your balance' : 'Insufficient balance',
                        onTap: () => setState(() => _walletGatewayChoice = 'wallet'),
                      ),
                      _methodTile(
                        selected: _walletGatewayChoice == 'gateway',
                        title: 'Card / payment gateway',
                        subtitle: 'Secure checkout',
                        onTap: () => setState(() => _walletGatewayChoice = 'gateway'),
                      ),
                    ],
                    if (showWallet &&
                        effective == 'wallet' &&
                        !canWalletPay &&
                        payable > 0.0001 &&
                        mode != 'gateway_only') ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: shortage > 0
                              ? () async {
                                  await context.push<double?>(
                                    AppRoutes.topUpWallet,
                                    extra: shortage,
                                  );
                                  if (context.mounted) {
                                    ref.invalidate(walletBalanceProvider);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.add_card_outlined, size: 20),
                          label: const Text('Top Up Wallet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConfig.primaryColor,
                            side: BorderSide(color: AppConfig.primaryColor.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (showWallet &&
                (mode == 'wallet_only' || (mode == 'wallet_and_gateway' && effective == 'wallet'))) ...[
              FilledButton.icon(
                onPressed: _busy || (effective == 'wallet' && !canWalletPay && payable > 0.0001)
                    ? null
                    : () => _payWallet(context),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Pay with wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
            if (showWallet &&
                (mode == 'wallet_only' || (mode == 'wallet_and_gateway' && effective == 'wallet')) &&
                showGateway &&
                mode == 'wallet_and_gateway')
              const SizedBox(height: AppSpacing.sm),
            if (showGateway &&
                (mode == 'gateway_only' || (mode == 'wallet_and_gateway' && effective == 'gateway'))) ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _payGateway(context, gw),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text('Pay with card'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppConfig.borderColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _methodTile({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: selected ? AppConfig.primaryColor.withValues(alpha: 0.12) : AppConfig.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppConfig.primaryColor : AppConfig.subtitleColor,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false, bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: AppConfig.subtitleColor)),
          Text(
            v,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? AppConfig.errorRed : AppConfig.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _payWallet(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final res = await payShipment(
        shipmentId: widget.shipmentId,
        paymentMethod: 'wallet',
      );
      if (!context.mounted) return;
      if (res['success'] == true) {
        ref.invalidate(walletBalanceProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipping paid.')),
        );
        context.go(AppRoutes.orders);
        return;
      }
      final msg = res['message']?.toString() ?? 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payGateway(BuildContext context, String? gateway) async {
    setState(() => _busy = true);
    try {
      final res = await payShipment(
        shipmentId: widget.shipmentId,
        paymentMethod: 'gateway',
        gateway: gateway,
      );
      if (!context.mounted) return;
      final url = res['checkout_url']?.toString().trim();
      if (url != null && url.isNotEmpty) {
        final web = await context.push<PaymentWebViewResult>(
          AppRoutes.paymentWebView,
          extra: url,
        );
        if (!context.mounted) return;
        ref.invalidate(walletBalanceProvider);
        if (web == PaymentWebViewResult.maybeCompleted || web == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('If payment completed, check My purchases → Shipments for status.')),
          );
        }
        context.go(AppRoutes.orders);
        return;
      }
      final msg = res['message']?.toString() ?? 'Could not start payment';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
