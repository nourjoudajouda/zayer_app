import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/network_image_preview.dart';
import 'models/warehouse_models.dart';
import 'warehouse_api.dart';
import 'warehouse_display_units.dart';
import 'warehouse_providers.dart';

enum _ShipmentFilter {
  all,
  awaitingPayment,
  paid,
  packed,
  shipped,
  delivered,
}

/// Lists outbound shipments (status, tracking, box photo).
class ShipmentsTrackingScreen extends ConsumerStatefulWidget {
  const ShipmentsTrackingScreen({super.key, this.hubEmbedded = false});

  final bool hubEmbedded;

  @override
  ConsumerState<ShipmentsTrackingScreen> createState() => _ShipmentsTrackingScreenState();
}

class _ShipmentsTrackingScreenState extends ConsumerState<ShipmentsTrackingScreen> {
  _ShipmentFilter _filter = _ShipmentFilter.all;

  Future<void> _onPullRefresh() async {
    ref.invalidate(outboundShipmentsProvider);
    await ref.read(outboundShipmentsProvider.future);
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

  String? _packedBoxSummary(OutboundShipmentApi s) {
    final w = s.finalWeightLb;
    final l = s.finalLengthIn;
    final wi = s.finalWidthIn;
    final h = s.finalHeightIn;
    final parts = <String>[];
    if (l != null && wi != null && h != null) {
      parts.add('Packed box: ${formatReceiptDimsIn(l, wi, h)}');
    }
    if (w != null && w > 0) {
      parts.add('Packed weight: ${formatReceiptWeightLb(w)}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Future<void> _promptConfirmDelivery(
    BuildContext context,
    WidgetRef ref,
    OutboundShipmentApi s,
  ) async {
    final noteCtrl = TextEditingController();
    int? rating;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Confirm delivery'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Did you receive shipment #${s.id}?',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Optional: rate your experience and leave a short note.',
                    style: TextStyle(fontSize: 13, color: AppConfig.subtitleColor),
                  ),
                  const SizedBox(height: 12),
                  Text('Rating (optional)', style: Theme.of(ctx).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        ChoiceChip(
                          label: Text('$i'),
                          selected: rating == i,
                          onSelected: (_) => setSt(() => rating = i),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setSt(() => rating = null),
                    child: const Text('Clear rating'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 2000,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes, I received it'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) {
      noteCtrl.dispose();
      return;
    }
    try {
      await confirmShipmentDelivery(
        shipmentId: s.id,
        rating: rating,
        note: noteCtrl.text,
      );
      noteCtrl.dispose();
      if (!context.mounted) return;
      ref.invalidate(outboundShipmentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — marked as delivered.')),
      );
    } on DioException catch (e) {
      noteCtrl.dispose();
      if (!context.mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Could not confirm')
          : 'Could not confirm';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      noteCtrl.dispose();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not confirm delivery.')),
      );
    }
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
        onRefresh: _onPullRefresh,
        child: ref.watch(outboundShipmentsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Error: $e')),
            ],
          ),
          data: (list) {
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
                            final boxUrl = s.finalBoxImage != null && s.finalBoxImage!.isNotEmpty
                                ? (s.finalBoxImage!.startsWith('http')
                                    ? s.finalBoxImage!
                                    : '${ApiClient.safeBaseUrl ?? ''}${s.finalBoxImage}')
                                : '';
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
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Shipping: \$${s.shippingCost.toStringAsFixed(2)} · '
                                            'Fees: \$${s.additionalFeesTotal.toStringAsFixed(2)} · '
                                            'Total: \$${s.totalShippingPayment.toStringAsFixed(2)} ${s.currency}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        if (s.additionalFeesTotal > 0.0001)
                                          Tooltip(
                                            message: kExtraFeeTooltipShort,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              icon: Icon(Icons.info_outline, size: 20, color: AppConfig.primaryColor),
                                              onPressed: () => showWarehouseExtraFeeDialog(context),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (boxUrl.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: TappableNetworkImage(
                                          imageUrl: boxUrl,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(8),
                                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                    if (_packedBoxSummary(s) != null) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppConfig.successGreen.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          _packedBoxSummary(s)!,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                        ),
                                      ),
                                    ],
                                    if (s.status.toLowerCase() == 'shipped') ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Material(
                                        color: AppConfig.primaryColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Package on the way',
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'When your order arrives, confirm receipt below. '
                                                'If something is wrong, contact support.',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppConfig.subtitleColor,
                                                      height: 1.35,
                                                    ),
                                              ),
                                              const SizedBox(height: AppSpacing.sm),
                                              FilledButton(
                                                onPressed: () => _promptConfirmDelivery(context, ref, s),
                                                child: const Text('I received my package'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (s.status.toLowerCase() == 'delivered') ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      if (s.deliveryRating != null)
                                        Text(
                                          'Your rating: ${s.deliveryRating}/5',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      if (s.deliveryNote != null && s.deliveryNote!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Your note: ${s.deliveryNote}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: AppConfig.subtitleColor,
                                                ),
                                          ),
                                        ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Items (${s.items.length})',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    for (final it in s.items)
                                      _ShipmentItemCollapsible(
                                        it: it,
                                        resolveUrl: _resolveUrl,
                                      ),
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

/// One shipment line: compact [ExpansionTile] (same idea as [MyWarehouseScreen]).
class _ShipmentItemCollapsible extends StatelessWidget {
  const _ShipmentItemCollapsible({
    required this.it,
    required this.resolveUrl,
  });

  final ShipmentLineApi it;
  final String Function(String?) resolveUrl;

  @override
  Widget build(BuildContext context) {
    final u = resolveUrl(it.imageUrl);
    final r = it.receipt;
    final thumbs = r?.images.map(resolveUrl).where((x) => x.isNotEmpty).toList() ?? [];
    final wLine = weightLineForItem(
      receiptWeightLb: r?.receivedWeight,
      catalogWeightKg: it.weightKg,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
          initiallyExpanded: false,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TappableNetworkImage(
                  imageUrl: u,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: (_, _, _) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.image_outlined, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  it.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              'Qty ${it.quantity} · tap to expand',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ),
          children: [
            Text(
              '${it.name} × ${it.quantity}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TappableNetworkImage(
                    imageUrl: u,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(6),
                    errorWidget: (_, _, _) => const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.image_outlined, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wLine != null)
                        Text(wLine, style: TextStyle(fontSize: 13, color: AppConfig.subtitleColor)),
                      if (it.dimensions != null && it.dimensions!.trim().isNotEmpty)
                        Text(
                          'Listed size (catalog): ${it.dimensions}',
                          style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                        ),
                      if (r != null &&
                          r.receivedLength != null &&
                          r.receivedWidth != null &&
                          r.receivedHeight != null)
                        Text(
                          'Received: ${formatReceiptDimsIn(r.receivedLength!, r.receivedWidth!, r.receivedHeight!)}',
                          style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                        ),
                      if (r != null && r.additionalFeeAmount > 0.0001)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'Extra fee: \$${r.additionalFeeAmount.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 13, color: AppConfig.warningOrange, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Tooltip(
                                message: kExtraFeeTooltipShort,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: Icon(Icons.info_outline, size: 18, color: AppConfig.primaryColor),
                                  onPressed: () => showWarehouseExtraFeeDialog(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (r != null &&
                          r.conditionNotes != null &&
                          r.conditionNotes!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  'Notes: ${r.conditionNotes}',
                                  style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                                ),
                              ),
                              Tooltip(
                                message: 'Condition / intake notes',
                                child: Icon(Icons.notes_outlined, size: 16, color: AppConfig.subtitleColor),
                              ),
                            ],
                          ),
                        ),
                      if (r != null &&
                          r.specialHandlingType != null &&
                          r.specialHandlingType!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Handling: ${r.specialHandlingType}',
                            style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (thumbs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Received photos',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppConfig.subtitleColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thumbs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (ctx, j) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TappableNetworkImage(
                      imageUrl: thumbs[j],
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(6),
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
