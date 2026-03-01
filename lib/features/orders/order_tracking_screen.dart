import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/order_model.dart';
import 'providers/orders_providers.dart';

/// Order tracking: delivery address card, warning banner, shipments (map + timeline + expanded logistics), Customs insight, Contact Support / View Order Details.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final Set<String> _expandedShipments = {};
  bool _logisticsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    return orderAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (order) {
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Tracking')),
            body: const Center(child: Text('Order not found')),
          );
        }
        return _OrderTrackingContent(
          order: order,
          expandedShipments: _expandedShipments,
          logisticsExpanded: _logisticsExpanded,
          onToggleShipment: (id) {
            setState(() {
              if (_expandedShipments.contains(id)) {
                _expandedShipments.remove(id);
              } else {
                _expandedShipments.add(id);
              }
            });
          },
          onToggleLogistics: () => setState(() => _logisticsExpanded = !_logisticsExpanded),
        );
      },
    );
  }
}

class _OrderTrackingContent extends StatelessWidget {
  const _OrderTrackingContent({
    required this.order,
    required this.expandedShipments,
    required this.logisticsExpanded,
    required this.onToggleShipment,
    required this.onToggleLogistics,
  });

  final OrderModel order;
  final Set<String> expandedShipments;
  final bool logisticsExpanded;
  final ValueChanged<String> onToggleShipment;
  final VoidCallback onToggleLogistics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Order Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('#${order.orderNumber}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeliveryAddressCard(
                status: order.statusLabel,
                address: order.shippingAddress ?? '—',
              ),
              const SizedBox(height: AppSpacing.md),
              _WarningBanner(),
              const SizedBox(height: AppSpacing.lg),
              if (order.shipments.isNotEmpty)
                for (final s in order.shipments)
                  _ShipmentTrackingCard(
                    shipment: s,
                    isExpanded: expandedShipments.contains(s.id),
                    onToggle: () => onToggleShipment(s.id),
                    logisticsExpanded: logisticsExpanded,
                    onToggleLogistics: onToggleLogistics,
                  ),
              const SizedBox(height: AppSpacing.lg),
              _CustomsInsightCard(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Questions about customs, delays, or delivery?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => context.push('${AppRoutes.contactSupport}?orderId=${order.id}'),
                icon: const Icon(Icons.headset_mic_outlined, size: 22),
                label: const Text('Contact Support'),
                style: FilledButton.styleFrom(backgroundColor: AppConfig.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
                child: const Text('View Order Details'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppConfig.successGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All Zayer shipments are fully insured against loss or damage.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.status, required this.address});

  final String status;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.4)),
                ),
                child: Text('• $status', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.primaryColor, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Icon(Icons.inventory_2_outlined, color: AppConfig.primaryColor, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Delivery Address', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor)),
          const SizedBox(height: 4),
          Text(address, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.warningOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_outlined, color: AppConfig.warningOrange, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Estimated delivery dates may vary based on customs processing times and local courier schedules.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentTrackingCard extends StatelessWidget {
  const _ShipmentTrackingCard({
    required this.shipment,
    required this.isExpanded,
    required this.onToggle,
    required this.logisticsExpanded,
    required this.onToggleLogistics,
  });

  final OrderShipment shipment;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool logisticsExpanded;
  final VoidCallback onToggleLogistics;

  @override
  Widget build(BuildContext context) {
    final isUsa = shipment.countryCode == 'US';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Text(isUsa ? '🇺🇸' : '🇹🇷', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(shipment.countryLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ...shipment.statusTags.take(2).map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConfig.borderColor.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppConfig.subtitleColor),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (isUsa && shipment.trackingEvents.isNotEmpty) ...[
              _MapPlaceholder(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < shipment.trackingEvents.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              shipment.trackingEvents[i].icon,
                              size: 20,
                              color: shipment.trackingEvents[i].isHighlighted ? AppConfig.primaryColor : AppConfig.subtitleColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.trackingEvents[i].title,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: shipment.trackingEvents[i].isHighlighted ? FontWeight.w600 : null,
                                          color: shipment.trackingEvents[i].isHighlighted ? AppConfig.primaryColor : null,
                                        ),
                                  ),
                                  Text(
                                    shipment.trackingEvents[i].subtitle,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _ExpandableLogistics(
                expanded: logisticsExpanded,
                onToggle: onToggleLogistics,
                weightKg: shipment.grossWeightKg,
                dimensions: shipment.dimensions,
                method: shipment.shippingMethod,
                insuranceConfirmed: shipment.insuranceConfirmed,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('No tracking events', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
              ),
          ],
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.map_outlined, size: 40, color: AppConfig.subtitleColor)),
          Positioned(
            top: 8,
            right: 8,
            child: Text(
              'Last updated: 14 mins ago',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableLogistics extends StatelessWidget {
  const _ExpandableLogistics({
    required this.expanded,
    required this.onToggle,
    this.weightKg,
    this.dimensions,
    this.method,
    this.insuranceConfirmed = false,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final double? weightKg;
  final String? dimensions;
  final String? method;
  final bool insuranceConfirmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text('EXPANDED LOGISTICS DATA', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.subtitleColor)),
                const SizedBox(width: 8),
                Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: AppConfig.subtitleColor),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Column(
              children: [
                if (weightKg != null) _LogisticsRow(icon: Icons.scale_outlined, label: 'Gross Weight', value: '$weightKg kg'),
                if (dimensions != null) _LogisticsRow(icon: Icons.straighten_outlined, label: 'Dimensions', value: dimensions!),
                if (method != null) _LogisticsRow(icon: Icons.flight_outlined, label: 'Method', value: method!),
                if (insuranceConfirmed) _LogisticsRow(icon: Icons.check_circle_outlined, label: 'Insurance', value: 'Confirmed Coverage', valueColor: AppConfig.successGreen),
              ],
            ),
          ),
      ],
    );
  }
}

class _LogisticsRow extends StatelessWidget {
  const _LogisticsRow({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConfig.subtitleColor),
          const SizedBox(width: 10),
          Text('$label:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: valueColor ?? AppConfig.textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CustomsInsightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, color: AppConfig.primaryColor, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customs Clearance Insight', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'This shipment is undergoing standard verification by UAE Customs authorities. Documentation has been submitted. Typical clearance time: 24-48 hours.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
