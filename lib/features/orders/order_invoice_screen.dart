import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_spacing.dart';
import 'models/order_model.dart';
import 'providers/orders_providers.dart';

String _invoiceIssueDateText(OrderModel order) {
  final inv = order.invoiceIssueDate?.trim();
  if (inv != null && inv.isNotEmpty) {
    return inv;
  }
  final placed = order.placedDate.trim();
  if (placed.isNotEmpty) {
    return placed;
  }
  return '—';
}

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

  Map<String, List<OrderShipment>> _groupShipmentsByCountry() {
    final grouped = <String, List<OrderShipment>>{};
    for (final s in order.shipments) {
      final key = (s.countryCode.isNotEmpty ? s.countryCode : s.countryLabel)
          .toUpperCase();
      grouped.putIfAbsent(key, () => <OrderShipment>[]).add(s);
    }
    return grouped;
  }

  List<Widget> _buildGroupedShipmentSections() {
    final grouped = _groupShipmentsByCountry();
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final shipments = entry.value;
      widgets.add(
        _InvoiceCountryCollapse(
          countryCode: shipments.first.countryCode,
          countryLabel: shipments.first.countryLabel,
          shipments: shipments,
        ),
      );
    }
    return widgets;
  }

  Future<void> _downloadInvoice(BuildContext context) async {
    try {
      final buffer = StringBuffer()
        ..writeln('INVOICE')
        ..writeln('Order: ${order.orderNumber}')
        ..writeln('Issue date: ${_invoiceIssueDateText(order)}')
        ..writeln('Total: ${order.totalAmount}')
        ..writeln('')
        ..writeln('Price lines:');
      for (final line in order.priceLines) {
        buffer.writeln('- ${line.label}: ${line.amount}');
      }

      final filename =
          'invoice_${order.orderNumber.replaceAll('#', '').replaceAll(' ', '_')}.txt';
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$filename',
      );
      await file.writeAsString(buffer.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invoice saved: ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save invoice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'INVOICE',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            Text(
              'Order ${order.orderNumber}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF3F4F6),
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
                  Expanded(
                    child: _StatusCard(
                      label: 'PAYMENT STATUS',
                      child: _PaymentStatusChip(
                        status: order.paymentStatus ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatusCard(
                      label: 'ORDER STATUS',
                      child: _OrderStatusChip(order: order),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusCard(
                label: 'ISSUE DATE',
                child: Text(
                  _invoiceIssueDateText(order),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ShippingAddressInvoiceCard(
                address: order.shippingAddress ?? '—',
              ),
              if (order.shipments.isNotEmpty)
                ..._buildGroupedShipmentSections(),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => _downloadInvoice(context),
                icon: const Icon(Icons.download_outlined, size: 22),
                label: const Text('Download PDF Invoice'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Share with Business Partners'),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Payment Summary / Cost breakdown is the section shown in the invoice UI.
              if (order.priceLines.isNotEmpty)
                _CostBreakdownSection(
                  lines: order.priceLines,
                  total: order.totalAmount,
                  paymentStatus: order.paymentStatus ?? '',
                  amountDueNow: order.amountDueNow,
                  consolidationSavings: order.consolidationSavings,
                ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.order});

  final OrderModel order;

  Color get _color {
    switch (order.status) {
      case OrderStatus.delivered:
        return AppConfig.successGreen;
      case OrderStatus.cancelled:
        return AppConfig.subtitleColor;
      case OrderStatus.pendingReview:
      case OrderStatus.pendingPayment:
        return AppConfig.warningOrange;
      default:
        return AppConfig.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, color: color, size: 22),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            order.statusChipUpper,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final String status;

  static String _displayLabel(String normalized, String rawFallback) {
    if (normalized.contains('pending_payment')) {
      return 'Pending payment';
    }
    if (normalized.contains('under_review') ||
        normalized.contains('under review')) {
      return 'Under review';
    }
    if (normalized.contains('paid') && !normalized.contains('unpaid')) {
      return 'Paid';
    }
    if (normalized.contains('pending')) {
      return 'Pending';
    }
    final raw = rawFallback.trim();
    if (raw.isEmpty) return '—';
    return raw
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .map(
          (w) =>
              w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().trim();
    if (normalized.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppConfig.subtitleColor,
        ),
      );
    }
    final isPaid = normalized.contains('paid') &&
        !normalized.contains('unpaid') &&
        !normalized.contains('pending_payment') &&
        !normalized.contains('under_review');
    final isPendingFlow = normalized.contains('pending') ||
        normalized.contains('under_review') ||
        normalized.contains('under review');
    final color = isPaid
        ? AppConfig.successGreen
        : isPendingFlow
        ? AppConfig.warningOrange
        : AppConfig.primaryColor;
    final label = _displayLabel(normalized, status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.hourglass_bottom,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ShippingAddressInvoiceCard extends StatelessWidget {
  const _ShippingAddressInvoiceCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final trimmed = address.trim();
    final body = trimmed.isEmpty ? '—' : trimmed;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppConfig.primaryColor,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.textColor,
                    height: 1.35,
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

class _InvoiceCountryCollapse extends StatelessWidget {
  const _InvoiceCountryCollapse({
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
        children: [
          for (final s in shipments) _InvoiceShipmentSection(shipment: s),
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
    final normalizedCountryLabel = shipment.countryLabel
        .replaceAll(RegExp(r'\s+shipment$', caseSensitive: false), '')
        .trim();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                isUsa ? '🇺🇸' : '🇹🇷',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                '${normalizedCountryLabel.toUpperCase()} SHIPMENT',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConfig.borderColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  shipment.id,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                isUsa ? Icons.flight_outlined : Icons.directions_boat_outlined,
                size: 18,
                color: AppConfig.subtitleColor,
              ),
              const SizedBox(width: 6),
              Text(
                shipment.shippingMethod,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Icon(
                Icons.schedule_outlined,
                size: 18,
                color: AppConfig.subtitleColor,
              ),
              const SizedBox(width: 4),
              Text(
                'ETA: ${shipment.eta}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
              ),
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
                    child: () {
                      final url = resolveAssetUrl(
                        item.imageUrl,
                        ApiClient.safeBaseUrl,
                      );
                      if (url == null || url.isEmpty) {
                        return const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppConfig.subtitleColor,
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, imageUrl) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, imageUrl, error) => const Icon(
                            Icons.shopping_bag_outlined,
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
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppConfig.subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.price,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (shipment.subtotal != null ||
              shipment.shippingFee != null ||
              shipment.customsDuties != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ShipmentCostRows(
              shipment: shipment,
              title: '${normalizedCountryLabel.toUpperCase()} SHIPMENT COSTS',
            ),
          ],
        ],
      ),
    );
  }
}

class _ShipmentCostRows extends StatelessWidget {
  const _ShipmentCostRows({required this.shipment, required this.title});

  final OrderShipment shipment;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppConfig.subtitleColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          if (shipment.subtotal != null)
            _CostRow(label: 'Subtotal', value: shipment.subtotal!),
          if (shipment.shippingFee != null)
            _CostRow(label: 'Intl. Shipping', value: shipment.shippingFee!),
          if (shipment.customsDuties != null)
            _CostRow(label: 'Customs & Duties', value: shipment.customsDuties!),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CostBreakdownSection extends StatelessWidget {
  const _CostBreakdownSection({
    required this.lines,
    required this.total,
    required this.paymentStatus,
    required this.amountDueNow,
    this.consolidationSavings,
  });

  final List<OrderPriceLine> lines;
  final String total;
  final String paymentStatus;
  final double? amountDueNow;
  final String? consolidationSavings;

  @override
  Widget build(BuildContext context) {
    final normalized = paymentStatus.toLowerCase();
    final isPaid = normalized.contains('paid') &&
        !normalized.contains('unpaid') &&
        !normalized.contains('pending_payment') &&
        !normalized.contains('under_review');
    final isPending = normalized.contains('pending') ||
        normalized.contains('under_review') ||
        normalized.contains('under review');

    final totalText = () {
      if (isPaid) return total;
      if (isPending && amountDueNow != null) {
        return '\$${amountDueNow!.toStringAsFixed(2)}';
      }
      return total;
    }();

    final headline = isPaid
        ? 'Total Amount Paid'
        : isPending
        ? 'Total Amount Due'
        : 'Total Amount';

    final showPaidCheck = isPaid;

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
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (line.isDiscount)
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppConfig.successGreen,
                    ),
                  if (line.isDiscount) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      line.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    line.amount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: line.isDiscount ? AppConfig.successGreen : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (consolidationSavings != null &&
              consolidationSavings!.trim().isNotEmpty &&
              consolidationSavings!.trim() != '\$0.00')
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppConfig.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consolidation Savings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    consolidationSavings!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.successGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  headline.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                        height: 1.25,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (showPaidCheck) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      color: AppConfig.primaryColor,
                      size: 22,
                    ),
                  ],
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
  const _PaymentMethodInvoiceCard({
    required this.label,
    this.lastFour,
    this.transactionId,
  });

  final String label;
  final String? lastFour;
  final String? transactionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: AppConfig.textColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'AP',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (lastFour != null)
                  Text(
                    'Mastercard • • • • $lastFour',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
                  ),
                if (transactionId != null)
                  Text(
                    'TRANSACTION ID $transactionId',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppConfig.subtitleColor,
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
