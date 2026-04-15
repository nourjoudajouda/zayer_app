import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../orders/providers/orders_providers.dart';
import '../warehouse/warehouse_providers.dart';
import 'providers/wallet_refund_to_wallet_providers.dart';
import 'providers/wallet_providers.dart';
import 'wallet_financial_api.dart';
import 'wallet_feedback.dart';

/// Request operational refund from an order or shipment (credits wallet when approved).
class RequestRefundToWalletScreen extends ConsumerStatefulWidget {
  const RequestRefundToWalletScreen({super.key});

  @override
  ConsumerState<RequestRefundToWalletScreen> createState() =>
      _RequestRefundToWalletScreenState();
}

class _RequestRefundToWalletScreenState
    extends ConsumerState<RequestRefundToWalletScreen> {
  String _sourceType = 'order';
  String? _selectedOrderId;
  String? _selectedShipmentId;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  double _maxRefundable = 0;
  bool _loadingMax = false;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMax() async {
    setState(() {
      _loadingMax = true;
      _maxRefundable = 0;
    });
    int? sid;
    if (_sourceType == 'order' && _selectedOrderId != null) {
      sid = int.tryParse(_selectedOrderId!);
    } else if (_sourceType == 'shipment' && _selectedShipmentId != null) {
      sid = int.tryParse(_selectedShipmentId!);
    }
    if (sid == null) {
      setState(() => _loadingMax = false);
      return;
    }
    final max = await fetchMaxRefundable(sourceType: _sourceType, sourceId: sid);
    if (mounted) {
      setState(() {
        _maxRefundable = max;
        _loadingMax = false;
      });
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    final reason = _reasonCtrl.text.trim();
    if (reason.length < 3) return;

    int? sid;
    if (_sourceType == 'order') {
      sid = int.tryParse(_selectedOrderId ?? '');
    } else {
      sid = int.tryParse(_selectedShipmentId ?? '');
    }
    if (sid == null) {
      await walletShowError(
        context,
        message: 'Select an order or shipment.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await createRefundToWallet(
        sourceType: _sourceType,
        sourceId: sid,
        amount: amount,
        reason: reason,
      );
      if (!mounted) return;
      if (result.ok) {
        ref.invalidate(walletRefundsToWalletProvider);
        ref.invalidate(walletBalanceProvider);
        await walletShowSuccess(
          context,
          message:
              result.data['message']?.toString() ?? 'Request submitted',
        );
        if (!mounted) return;
        context.pop();
        return;
      }
      final msg = result.data['message']?.toString() ?? 'Request failed';
      await walletShowError(context, message: msg);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final shipAsync = ref.watch(outboundShipmentsProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Refund to wallet'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose whether this refund is for an order total or a shipment shipping payment. '
                'Max refundable is based on that transaction, not your wallet balance.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'order', label: Text('Order')),
                  ButtonSegment(value: 'shipment', label: Text('Shipment')),
                ],
                selected: {_sourceType},
                onSelectionChanged: (s) {
                  setState(() {
                    _sourceType = s.first;
                    _selectedOrderId = null;
                    _selectedShipmentId = null;
                    _maxRefundable = 0;
                  });
                  _loadMax();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_sourceType == 'order')
                ordersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Orders: $e'),
                  data: (orders) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Order',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedOrderId,
                      items: [
                        for (final o in orders)
                          DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              '${o.orderNumber} · ${o.totalAmount}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedOrderId = v);
                        _loadMax();
                      },
                    );
                  },
                )
              else
                shipAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Shipments: $e'),
                  data: (shipments) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Shipment',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedShipmentId,
                      items: [
                        for (final s in shipments)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '#${s.id} · ${s.status} · \$${s.totalShippingPayment.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedShipmentId = v);
                        _loadMax();
                      },
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingMax)
                const LinearProgressIndicator()
              else
                Text(
                  'Max refundable: \$${_maxRefundable.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.primaryColor,
                      ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (USD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
