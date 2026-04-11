import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import 'models/warehouse_models.dart';
import 'warehouse_api.dart';

enum _ShipmentFilter {
  all,
  awaitingPayment,
  paid,
  packed,
  shipped,
  delivered,
}

/// Lists outbound shipments (status, tracking, box photo).
class ShipmentsTrackingScreen extends StatefulWidget {
  const ShipmentsTrackingScreen({super.key, this.hubEmbedded = false});

  final bool hubEmbedded;

  @override
  State<ShipmentsTrackingScreen> createState() => _ShipmentsTrackingScreenState();
}

class _ShipmentsTrackingScreenState extends State<ShipmentsTrackingScreen> {
  late Future<List<OutboundShipmentApi>> _future;
  _ShipmentFilter _filter = _ShipmentFilter.all;

  @override
  void initState() {
    super.initState();
    _future = fetchShipments();
  }

  bool _matchesFilter(OutboundShipmentApi s) {
    final st = s.status.toLowerCase().trim();
    switch (_filter) {
      case _ShipmentFilter.all:
        return true;
      case _ShipmentFilter.awaitingPayment:
        return st == 'draft' || st == 'awaiting_payment';
      case _ShipmentFilter.paid:
        return st == 'paid';
      case _ShipmentFilter.packed:
        return st == 'packed';
      case _ShipmentFilter.shipped:
        return st == 'shipped';
      case _ShipmentFilter.delivered:
        return st == 'delivered';
    }
  }

  String _resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final p = path.trim();
    return p.startsWith('http') ? p : '${ApiClient.safeBaseUrl ?? ''}$p';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: widget.hubEmbedded
          ? null
          : AppBar(
              title: const Text('My shipments'),
              backgroundColor: AppConfig.backgroundColor,
              foregroundColor: AppConfig.textColor,
              elevation: 0,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = fetchShipments());
          await _future;
        },
        child: FutureBuilder<List<OutboundShipmentApi>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text('Error: ${snap.error}')),
                ],
              );
            }
            final list = snap.data ?? [];
            final filtered = list.where(_matchesFilter).toList();
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Center(
                      child: Text(
                        'No shipments yet.',
                        style: TextStyle(color: AppConfig.subtitleColor),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    children: [
                      _chip('All', _ShipmentFilter.all),
                      _chip('Awaiting payment', _ShipmentFilter.awaitingPayment),
                      _chip('Paid', _ShipmentFilter.paid),
                      _chip('Packed', _ShipmentFilter.packed),
                      _chip('Shipped', _ShipmentFilter.shipped),
                      _chip('Delivered', _ShipmentFilter.delivered),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No shipments in this filter.',
                            style: TextStyle(color: AppConfig.subtitleColor),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Shipment #${s.id}',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Chip(
                                          label: Text(s.status),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    if (s.paymentStatus != null && s.paymentStatus!.isNotEmpty)
                                      Text(
                                        'Payment: ${s.paymentStatus}',
                                        style: TextStyle(color: AppConfig.subtitleColor, fontSize: 12),
                                      ),
                                    if (s.destinationSummary != null && s.destinationSummary!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'To: ${s.destinationSummary}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                    if (s.carrier != null && s.carrier!.isNotEmpty)
                                      Text('Carrier: ${s.carrier}', style: TextStyle(color: AppConfig.subtitleColor)),
                                    if (s.trackingNumber != null && s.trackingNumber!.isNotEmpty)
                                      Text('Tracking: ${s.trackingNumber}', style: TextStyle(color: AppConfig.subtitleColor)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Shipping: \$${s.shippingCost.toStringAsFixed(2)} · Fees: \$${s.additionalFeesTotal.toStringAsFixed(2)} · Total: \$${s.totalShippingPayment.toStringAsFixed(2)} ${s.currency}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (s.finalBoxImage != null && s.finalBoxImage!.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: s.finalBoxImage!.startsWith('http')
                                              ? s.finalBoxImage!
                                              : '${ApiClient.safeBaseUrl ?? ''}${s.finalBoxImage}',
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('Items', style: Theme.of(context).textTheme.labelLarge),
                                    ...s.items.map((it) => _ShipmentLineRow(it: it, resolveUrl: _resolveUrl)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, _ShipmentFilter value) {
    final sel = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppConfig.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConfig.primaryColor,
      ),
    );
  }
}

class _ShipmentLineRow extends StatelessWidget {
  const _ShipmentLineRow({required this.it, required this.resolveUrl});

  final ShipmentLineApi it;
  final String Function(String?) resolveUrl;

  @override
  Widget build(BuildContext context) {
    final u = resolveUrl(it.imageUrl);
    final r = it.receipt;
    final thumbs = r?.images.map(resolveUrl).where((x) => x.isNotEmpty).toList() ?? [];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 48,
              child: u.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: u,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, size: 22),
                    )
                  : const Icon(Icons.image_outlined, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${it.name} × ${it.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (it.weightKg != null)
                  Text('Weight: ${it.weightKg!.toStringAsFixed(2)} kg', style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor)),
                if (it.dimensions != null && it.dimensions!.trim().isNotEmpty)
                  Text('Size: ${it.dimensions}', style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor)),
                if (r != null &&
                    r.receivedLength != null &&
                    r.receivedWidth != null &&
                    r.receivedHeight != null)
                  Text(
                    'Received: ${r.receivedLength!.toStringAsFixed(0)}×${r.receivedWidth!.toStringAsFixed(0)}×${r.receivedHeight!.toStringAsFixed(0)} cm',
                    style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                  ),
                if (r != null && r.additionalFeeAmount > 0.0001)
                  Text(
                    'Extra fee: \$${r.additionalFeeAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: AppConfig.warningOrange),
                  ),
                if (r != null &&
                    r.conditionNotes != null &&
                    r.conditionNotes!.trim().isNotEmpty)
                  Text(
                    'Notes: ${r.conditionNotes}',
                    style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                  ),
                if (thumbs.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: thumbs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (ctx, j) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: thumbs[j],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
