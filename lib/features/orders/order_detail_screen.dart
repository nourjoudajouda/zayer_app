import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/order_model.dart';
import 'providers/orders_providers.dart';
import 'widgets/order_badge_pill.dart';

/// Detailed order view: order #, date, status, shipping address, shipment timeline, product(s), price details, Contact Support, payment method.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return orderAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Couldn\'t load this order. Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _OrderDetailContent(order: order);
      },
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status == OrderStatus.delivered
        ? AppConfig.successGreen
        : order.status == OrderStatus.cancelled
            ? AppConfig.errorRed
            : order.status == OrderStatus.pendingPayment ||
                    order.status == OrderStatus.pendingReview
                ? AppConfig.warningOrange
                : AppConfig.primaryColor;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order.placedDate, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              order.statusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (order.shippingAddress != null) _ShippingAddressCard(address: order.shippingAddress!),
              if (order.shipments.isNotEmpty) ...[
                for (final s in order.shipments) _ShipmentSection(shipment: s),
              ],
              if (order.priceLines.isNotEmpty) _PriceDetailsCard(lines: order.priceLines),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.push('${AppRoutes.contactSupport}?orderId=${order.id}'),
                  icon: const Icon(Icons.headset_mic_outlined, size: 22),
                  label: const Text('Contact Support'),
                  style: FilledButton.styleFrom(backgroundColor: AppConfig.primaryColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (order.canTrack)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('${AppRoutes.orderTracking}/${order.id}'),
                        child: const Text('Track Order'),
                      ),
                    ),
                  if (order.canTrack) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('${AppRoutes.orderInvoice}/${order.id}'),
                      child: const Text('View Invoice'),
                    ),
                  ),
                ],
              ),
              if (order.paymentMethodLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _PaymentMethodCard(
                  label: order.paymentMethodLabel!,
                  lastFour: order.paymentMethodLastFour,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppConfig.lightBlueBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.lock_outline, color: AppConfig.primaryColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shipping Address', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(address, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor)),
              ],
            ),
          ),
          Icon(Icons.info_outline, size: 20, color: AppConfig.subtitleColor),
        ],
      ),
    );
  }
}

class _ShipmentSection extends StatelessWidget {
  const _ShipmentSection({required this.shipment});

  final OrderShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _shipmentColor(shipment.countryCode),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shipment.countryLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _TrackingTimeline(events: shipment.trackingEvents),
          if (shipment.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...shipment.items.map((item) => _OrderLineItemTile(item: item)),
            if (shipment.grossWeightKg != null || shipment.dimensions != null || shipment.shippingMethod.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (shipment.grossWeightKg != null)
                      Text('WEIGHT: ${shipment.grossWeightKg} kg', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                    if (shipment.dimensions != null && shipment.dimensions!.isNotEmpty)
                      Text('DIMENSIONS: ${shipment.dimensions}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                    Text('METHOD: ${shipment.shippingMethod}', style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static Color _shipmentColor(String code) {
    if (code == 'US') return const Color(0xFF6B4EAA);
    if (code == 'TR') return Colors.orange;
    return AppConfig.primaryColor;
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.events});

  final List<OrderTrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  events[i].icon,
                  size: 22,
                  color: events[i].isHighlighted ? AppConfig.primaryColor : AppConfig.subtitleColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: events[i].isHighlighted ? FontWeight.w600 : null,
                              color: events[i].isHighlighted ? AppConfig.primaryColor : AppConfig.textColor,
                            ),
                      ),
                      Text(
                        events[i].subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < events.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                child: Container(width: 2, height: 16, color: AppConfig.borderColor),
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderLineItemTile extends StatelessWidget {
  const _OrderLineItemTile({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smartphone_outlined, color: AppConfig.subtitleColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('${item.storeName} • SKU: ${item.sku}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.badges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: item.badges.map((b) => OrderBadgePill(label: b, isWarning: b.toLowerCase() == 'lithium')).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.price, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text('Qty: ${item.quantity}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceDetailsCard extends StatelessWidget {
  const _PriceDetailsCard({required this.lines});

  final List<OrderPriceLine> lines;

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
          Text('Price Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (line.isDiscount) Icon(Icons.bolt, size: 18, color: AppConfig.successGreen),
                  if (line.isDiscount) const SizedBox(width: 4),
                  Expanded(child: Text(line.label, style: Theme.of(context).textTheme.bodyMedium)),
                  Text(
                    line.amount,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: line.isDiscount ? AppConfig.successGreen : null,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.label, this.lastFour});

  final String label;
  final String? lastFour;

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
                Text('Payment Method', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
                Text(lastFour != null ? '$label (Card ending in $lastFour)' : label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: AppConfig.subtitleColor, size: 24),
        ],
      ),
    );
  }
}
