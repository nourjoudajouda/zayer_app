import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
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

  List<Widget> _buildGroupedShipmentSections() {
    final grouped = <String, List<OrderShipment>>{};
    for (final s in order.shipments) {
      final key = (s.countryCode.isNotEmpty ? s.countryCode : s.countryLabel)
          .toUpperCase();
      grouped.putIfAbsent(key, () => <OrderShipment>[]).add(s);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final list = entry.value;
      widgets.add(
        _CountryShipmentCollapse(
          countryCode: list.first.countryCode,
          countryLabel: list.first.countryLabel,
          shipments: list,
        ),
      );
    }
    return widgets;
  }

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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        toolbarHeight: 62,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.orders);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.isPurchaseAssistant)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: const Text('Purchase Assistant'),
                    padding: EdgeInsets.zero,
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
            Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              order.placedOnLine,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF3F4F6),
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrderStatusSection(order: order, statusColor: statusColor),
              const SizedBox(height: AppSpacing.md),
              if (order.shippingAddress != null)
                _ShippingAddressCard(address: order.shippingAddress!),
              if (order.shipments.isNotEmpty)
                ..._buildGroupedShipmentSections(),
              if (order.priceLines.isNotEmpty)
                _PriceDetailsCard(
                  lines: order.priceLines,
                  total: order.totalAmount,
                ),
              const SizedBox(height: 84),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.orderInvoice}/${order.id}'),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('View Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.textColor,
                  side: BorderSide(color: AppConfig.borderColor),
                  backgroundColor: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '${AppRoutes.contactSupport}?orderId=${order.id}',
                ),
                icon: const Icon(Icons.headset_mic_outlined, size: 18),
                label: const Text('Contact Support'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusSection extends StatelessWidget {
  const _OrderStatusSection({required this.order, required this.statusColor});

  final OrderModel order;
  final Color statusColor;

  String get _paymentLine {
    final p = order.paymentStatus?.trim().toLowerCase() ?? '';
    if (p.isEmpty) {
      return '';
    }
    if (p == 'paid') {
      return 'Payment: Paid';
    }
    if (p.contains('pending')) {
      return 'Payment: Pending';
    }
    return 'Payment: ${order.paymentStatus}';
  }

  @override
  Widget build(BuildContext context) {
    final paymentLine = _paymentLine;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order status',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppConfig.subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.statusChipUpper,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          if (paymentLine.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              paymentLine,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountryShipmentCollapse extends StatelessWidget {
  const _CountryShipmentCollapse({
    required this.countryCode,
    required this.countryLabel,
    required this.shipments,
  });

  final String countryCode;
  final String countryLabel;
  final List<OrderShipment> shipments;

  @override
  Widget build(BuildContext context) {
    final flag = countryCode.toUpperCase() == 'US'
        ? '🇺🇸'
        : (countryCode.toUpperCase() == 'TR' ? '🇹🇷' : '📦');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        title: Text(
          '$flag $countryLabel Shipments (${shipments.length})',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [for (final s in shipments) _ShipmentSection(shipment: s)],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHIPPING ADDRESS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address.split(',').first,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: AppConfig.subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Address-based cost calculation applied',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppConfig.subtitleColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 94,
              height: 94,
              color: const Color(0xFFE7EEF8),
              child: Icon(
                Icons.map_outlined,
                color: AppConfig.primaryColor.withValues(alpha: 0.6),
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentSection extends StatefulWidget {
  const _ShipmentSection({required this.shipment});

  final OrderShipment shipment;

  @override
  State<_ShipmentSection> createState() => _ShipmentSectionState();
}

class _ShipmentSectionState extends State<_ShipmentSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConfig.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppConfig.borderColor),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              onExpansionChanged: (v) => setState(() => _expanded = v),
              tilePadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              title: Row(
                children: [
                  Text(
                    _flagForCountry(widget.shipment.countryCode),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.shipment.countryLabel} Shipment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: AppConfig.subtitleColor,
              ),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _smallTag(
                      context,
                      widget.shipment.shippingMethod.isEmpty
                          ? 'STANDARD'
                          : widget.shipment.shippingMethod.toUpperCase(),
                      const Color(0xFFEFF6FF),
                      AppConfig.primaryColor,
                    ),
                    if (widget.shipment.statusTags.isNotEmpty)
                      ...widget.shipment.statusTags.map(
                        (e) => _smallTag(
                          context,
                          e.toUpperCase(),
                          const Color(0xFFF5F3FF),
                          const Color(0xFF7C3AED),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTIMATED ARRIVAL',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppConfig.subtitleColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.shipment.eta.isEmpty
                                  ? 'TBD'
                                  : widget.shipment.eta,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.flight_land_rounded,
                        color: AppConfig.primaryColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        context,
                        'WEIGHT',
                        widget.shipment.grossWeightKg != null
                            ? '${widget.shipment.grossWeightKg} kg'
                            : '--',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _metricBox(
                        context,
                        'SIZE',
                        (widget.shipment.dimensions != null &&
                                widget.shipment.dimensions!.isNotEmpty)
                            ? widget.shipment.dimensions!
                            : '--',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _metricBox(
                        context,
                        'INSURANCE',
                        widget.shipment.insuranceConfirmed ? 'Active' : '--',
                        valueColor: widget.shipment.insuranceConfirmed
                            ? AppConfig.successGreen
                            : null,
                      ),
                    ),
                  ],
                ),
                if (widget.shipment.trackingEvents.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _TrackingTimeline(events: widget.shipment.trackingEvents),
                ],
              ],
            ),
          ),
          if (widget.shipment.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'ITEMS IN SHIPMENT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppConfig.subtitleColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.shipment.items.map(
              (item) => _OrderLineItemTile(item: item),
            ),
          ],
        ],
      ),
    );
  }

  static String _flagForCountry(String code) {
    if (code.toUpperCase() == 'US') return '🇺🇸';
    if (code.toUpperCase() == 'TR') return '🇹🇷';
    return '📦';
  }

  Widget _smallTag(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _metricBox(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppConfig.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.events});

  final List<OrderTrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < events.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: events[i].isHighlighted
                          ? AppConfig.primaryColor
                          : Colors.white,
                      border: Border.all(
                        color: events[i].isHighlighted
                            ? AppConfig.primaryColor
                            : AppConfig.borderColor,
                        width: 2,
                      ),
                    ),
                  ),
                  if (i < events.length - 1)
                    Container(
                      width: 2,
                      height: 26,
                      color: AppConfig.borderColor,
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        events[i].title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: events[i].isHighlighted
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        events[i].subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: events[i].isHighlighted
                              ? AppConfig.primaryColor
                              : AppConfig.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrderLineItemTile extends StatelessWidget {
  const _OrderLineItemTile({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final sku = item.sku.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(12),
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
            child: () {
              final url = resolveAssetUrl(item.imageUrl, ApiClient.safeBaseUrl);
              if (url == null || url.isEmpty) {
                return const Icon(
                  Icons.image_outlined,
                  color: AppConfig.subtitleColor,
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) => const Icon(
                    Icons.image_outlined,
                    color: AppConfig.subtitleColor,
                  ),
                ),
              );
            }(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.storeName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sku.isNotEmpty
                      ? 'SKU: $sku • Qty: ${item.quantity}'
                      : 'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.badges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: item.badges
                        .map(
                          (b) => OrderBadgePill(
                            label: b,
                            isWarning: b.toLowerCase() == 'lithium',
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.price,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceDetailsCard extends StatelessWidget {
  const _PriceDetailsCard({required this.lines, required this.total});

  final List<OrderPriceLine> lines;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Payment Summary',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Paid',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                total,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
