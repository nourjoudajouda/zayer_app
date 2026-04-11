import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/warehouse_models.dart';
import 'warehouse_api.dart';

/// Items that arrived at the warehouse (ready to combine into a shipment).
class MyWarehouseScreen extends StatefulWidget {
  const MyWarehouseScreen({super.key, this.hubEmbedded = false});

  final bool hubEmbedded;

  @override
  State<MyWarehouseScreen> createState() => _MyWarehouseScreenState();
}

class _MyWarehouseScreenState extends State<MyWarehouseScreen> {
  late Future<List<WarehouseItemApi>> _future;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseItems();
  }

  void _refresh() {
    setState(() {
      _future = fetchWarehouseItems();
      _selected.clear();
    });
  }

  String _resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final p = path.trim();
    return p.startsWith('http') ? p : '${ApiClient.safeBaseUrl ?? ''}$p';
  }

  ({double totalWeightKg, double extraFees, int selectedCount}) _selectionTotals(
    List<WarehouseItemApi> items,
  ) {
    var w = 0.0;
    var f = 0.0;
    var c = 0;
    for (final it in items) {
      if (!_selected.contains(it.id)) continue;
      c++;
      final r = it.receipt;
      final rw = r?.receivedWeight ?? it.weightKg ?? 0;
      w += rw;
      f += r?.additionalFeeAmount ?? 0;
    }
    return (totalWeightKg: w, extraFees: f, selectedCount: c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: widget.hubEmbedded
          ? null
          : AppBar(
              title: const Text('My Warehouse'),
              backgroundColor: AppConfig.backgroundColor,
              foregroundColor: AppConfig.textColor,
              elevation: 0,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Shipping will be calculated after items arrive at the warehouse. '
              'Select items to ship together, then pay shipping separately from your product order.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: FutureBuilder<List<WarehouseItemApi>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load items', style: TextStyle(color: AppConfig.subtitleColor)),
                        TextButton(onPressed: _refresh, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items at the warehouse yet.',
                      style: TextStyle(color: AppConfig.subtitleColor),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final sel = _selected.contains(it.id);
                    final productUrl = _resolveUrl(it.imageUrl);
                    final r = it.receipt;
                    final receiptUrls = r?.images.map(_resolveUrl).where((u) => u.isNotEmpty).toList() ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (sel) {
                              _selected.remove(it.id);
                            } else {
                              _selected.add(it.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: sel,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(it.id);
                                        } else {
                                          _selected.remove(it.id);
                                        }
                                      });
                                    },
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: productUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: productUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(Icons.image_outlined),
                                            )
                                          : const Icon(Icons.image_outlined),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      it.name,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              if (receiptUrls.isNotEmpty) ...[
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
                                  height: 52,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: receiptUrls.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                                    itemBuilder: (ctx, j) => ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: receiptUrls[j],
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 52,
                                          height: 52,
                                          color: AppConfig.borderColor.withValues(alpha: 0.3),
                                          child: const Icon(Icons.broken_image_outlined, size: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppConfig.borderColor),
                                ),
                                child: Text(
                                  _weightDimBlock(it),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                                ),
                              ),
                              if (r != null && r.additionalFeeAmount > 0.0001) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppConfig.warningOrange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Extra fees: \$${r.additionalFeeAmount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppConfig.textColor,
                                        ),
                                  ),
                                ),
                              ],
                              if (r != null &&
                                  r.conditionNotes != null &&
                                  r.conditionNotes!.trim().isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Notes: ${r.conditionNotes}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                                ),
                              ],
                              if (r != null &&
                                  r.specialHandlingType != null &&
                                  r.specialHandlingType!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Handling: ${r.specialHandlingType}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<List<WarehouseItemApi>>(
                    future: _future,
                    builder: (context, snap) {
                      final items = snap.data ?? [];
                      final t = _selectionTotals(items);
                      if (t.selectedCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppConfig.cardColor,
                            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                            border: Border.all(color: AppConfig.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selection (${t.selectedCount})',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Σ weight (est.): ${t.totalWeightKg.toStringAsFixed(2)} kg',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (t.extraFees > 0.0001)
                                Text(
                                  'Σ extra fees: \$${t.extraFees.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => context.push(
                              AppRoutes.shipmentCreate,
                              extra: _selected.toList(),
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continue to shipment'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weightDimBlock(WarehouseItemApi it) {
    final r = it.receipt;
    final w = r?.receivedWeight ?? it.weightKg;
    final lines = <String>[];
    if (w != null) lines.add('Weight: ${w.toStringAsFixed(2)} kg');
    if (r != null &&
        r.receivedLength != null &&
        r.receivedWidth != null &&
        r.receivedHeight != null) {
      lines.add(
        'Received size: ${r.receivedLength!.toStringAsFixed(0)}×${r.receivedWidth!.toStringAsFixed(0)}×${r.receivedHeight!.toStringAsFixed(0)} cm',
      );
    } else if (it.dimensions != null && it.dimensions!.trim().isNotEmpty) {
      lines.add('Listed size: ${it.dimensions}');
    }
    lines.add('Qty ${it.quantity}');
    return lines.join('\n');
  }
}
