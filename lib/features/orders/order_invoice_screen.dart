import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'models/order_model.dart';
import 'providers/orders_providers.dart';

/// Digital order invoice: Payment Status, Issue Date, Shipping Address, USA/Turkey Shipments with items and costs, Download PDF / Share, Cost breakdown, Total, Payment method.
class OrderInvoiceScreen extends ConsumerWidget {
  const OrderInvoiceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return orderAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Invoice')),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _OrderInvoiceContent(order: order);
      },
    );
  }
}

class _OrderInvoiceContent extends StatelessWidget {
  const _OrderInvoiceContent({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('INVOICE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text('Order ${order.orderNumber}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _StatusCard(label: 'PAYMENT STATUS', child: _PaidChip())),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatusCard(
                      label: 'ISSUE DATE',
                      child: Text(
                        order.invoiceIssueDate ?? order.placedDate,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ShippingAddressInvoiceCard(address: order.shippingAddress ?? '—'),
              if (order.shipments.isNotEmpty) ...[
                for (final s in order.shipments) _InvoiceShipmentSection(shipment: s),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 22),
                label: const Text('Download PDF Invoice'),
                style: FilledButton.styleFrom(backgroundColor: AppConfig.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Share with Business Partners'),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (order.priceLines.isNotEmpty) _CostBreakdownSection(lines: order.priceLines, total: order.totalAmount, consolidationSavings: order.consolidationSavings),
              if (order.paymentMethodLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _PaymentMethodInvoiceCard(
                  label: order.paymentMethodLabel!,
                  lastFour: order.paymentMethodLastFour,
                  transactionId: order.transactionId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PaidChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppConfig.successGreen, size: 22),
        const SizedBox(width: 6),
        Text('Paid', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppConfig.successGreen, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ShippingAddressInvoiceCard extends StatelessWidget {
  const _ShippingAddressInvoiceCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: AppConfig.primaryColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shipping Address', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                const SizedBox(height: 4),
                Text('John Doe', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(address, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceShipmentSection extends StatelessWidget {
  const _InvoiceShipmentSection({required this.shipment});

  final OrderShipment shipment;

  @override
  Widget build(BuildContext context) {
    final isUsa = shipment.countryCode == 'US';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(isUsa ? '🇺🇸' : '🇹🇷', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(shipment.countryLabel.toUpperCase(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConfig.borderColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(shipment.id, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(isUsa ? Icons.flight_outlined : Icons.directions_boat_outlined, size: 18, color: AppConfig.subtitleColor),
              const SizedBox(width: 6),
              Text(shipment.shippingMethod, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Icon(Icons.schedule_outlined, size: 18, color: AppConfig.subtitleColor),
              const SizedBox(width: 4),
              Text('ETA: ${shipment.eta}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in shipment.items)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                border: Border.all(color: AppConfig.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConfig.borderColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppConfig.subtitleColor),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        Text('Qty: ${item.quantity}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                      ],
                    ),
                  ),
                  Text(item.price, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CostBreakdownSection extends StatelessWidget {
  const _CostBreakdownSection({required this.lines, required this.total, this.consolidationSavings});

  final List<OrderPriceLine> lines;
  final String total;
  final String? consolidationSavings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (line.isDiscount) Icon(Icons.auto_awesome, size: 16, color: AppConfig.successGreen),
                    if (line.isDiscount) const SizedBox(width: 4),
                    Expanded(child: Text(line.label, style: Theme.of(context).textTheme.bodySmall)),
                    Text(
                      line.amount,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: line.isDiscount ? AppConfig.successGreen : null,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL AMOUNT PAID', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.subtitleColor)),
              Row(
                children: [
                  Text(total, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppConfig.primaryColor, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: AppConfig.primaryColor, size: 22),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodInvoiceCard extends StatelessWidget {
  const _PaymentMethodInvoiceCard({required this.label, this.lastFour, this.transactionId});

  final String label;
  final String? lastFour;
  final String? transactionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(color: AppConfig.textColor, borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Text('AP', style: TextStyle(color: Colors.white, fontSize: 10))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (lastFour != null) Text('Mastercard • • • • $lastFour', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
                if (transactionId != null) Text('TRANSACTION ID $transactionId', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
