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

/// Second payment: shipping + fees only (wallet or card).
class ShipmentShippingPaymentScreen extends ConsumerStatefulWidget {
  const ShipmentShippingPaymentScreen({
    super.key,
    required this.shipmentId,
    required this.total,
    required this.breakdown,
    required this.shipment,
  });

  final String shipmentId;
  final double total;
  final Map<String, dynamic> breakdown;
  final OutboundShipmentApi shipment;

  @override
  ConsumerState<ShipmentShippingPaymentScreen> createState() =>
      _ShipmentShippingPaymentScreenState();
}

class _ShipmentShippingPaymentScreenState
    extends ConsumerState<ShipmentShippingPaymentScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final gw = ref.watch(bootstrapConfigProvider).valueOrNull?.paymentGateways?.defaultGatewayCode;

    final ship = widget.breakdown['shipping_cost'];
    final add = widget.breakdown['additional_fees'];
    final shipStr = ship is num ? ship.toDouble().toStringAsFixed(2) : '—';
    final addStr = add is num ? add.toDouble().toStringAsFixed(2) : '—';

    return Scaffold(
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
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _busy ? null : () => _payWallet(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Pay with wallet'),
            style: FilledButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
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
              color: AppConfig.textColor,
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
        context.go(AppRoutes.shipmentsTracking);
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
            const SnackBar(content: Text('If payment completed, check My shipments for status.')),
          );
        }
        context.go(AppRoutes.shipmentsTracking);
        return;
      }
      final msg = res['message']?.toString() ?? 'Could not start payment';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
