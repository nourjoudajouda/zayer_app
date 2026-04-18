import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/network_image_preview.dart';
import 'models/warehouse_models.dart';
import 'warehouse_display_units.dart';
import 'warehouse_providers.dart';

/// Items that arrived at the warehouse (ready to combine into a shipment).
class MyWarehouseScreen extends ConsumerStatefulWidget {
  const MyWarehouseScreen({super.key, this.hubEmbedded = false});

  final bool hubEmbedded;

  @override
  ConsumerState<MyWarehouseScreen> createState() => _MyWarehouseScreenState();
}

class _MyWarehouseScreenState extends ConsumerState<MyWarehouseScreen> {
  final Set<String> _selected = {};

  Future<void> _onPullRefresh() async {
    ref.invalidate(warehouseItemsProvider);
    await ref.read(warehouseItemsProvider.future);
  }

  void _retry() {
    ref.invalidate(warehouseItemsProvider);
  }

  String _resolveUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final p = path.trim();
    return p.startsWith('http') ? p : '${ApiClient.safeBaseUrl ?? ''}$p';
  }

  /// Weight for receipt lines is lb; catalog [weightKg] is converted to lb for totals.
  double _lineWeightLb(WarehouseItemApi it) {
    final r = it.receipt;
    if (r?.receivedWeight != null) return r!.receivedWeight!;
    final kg = it.weightKg;
    if (kg != null) return kg * 2.2046226218;
    return 0;
  }

  ({double totalWeightLb, double extraFees, int selectedCount}) _selectionTotals(
    List<WarehouseItemApi> items,
  ) {
    var w = 0.0;
    var f = 0.0;
    var c = 0;
    for (final it in items) {
      if (!_selected.contains(it.id)) continue;
      c++;
      w += _lineWeightLb(it);
      f += it.receipt?.additionalFeeAmount ?? 0;
    }
    return (totalWeightLb: w, extraFees: f, selectedCount: c);
  }

  /// Compact per-line dimension hints for selected items (receipt L×W×H in inches).
  String? _selectionDimsSummary(List<WarehouseItemApi> items) {
    final lines = <String>[];
    for (final it in items) {
      if (!_selected.contains(it.id)) continue;
      final r = it.receipt;
      if (r != null &&
          r.receivedLength != null &&
          r.receivedWidth != null &&
          r.receivedHeight != null) {
        final shortName = it.name.length > 28 ? '${it.name.substring(0, 28)}…' : it.name;
        lines.add(
          '• $shortName: ${formatReceiptDimsIn(r.receivedLength!, r.receivedWidth!, r.receivedHeight!)}',
        );
      }
    }
    if (lines.isEmpty) return null;
    if (lines.length <= 5) return lines.join('\n');
    return '${lines.take(5).join('\n')}\n…';
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
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
            child: ref.watch(warehouseItemsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load items', style: TextStyle(color: AppConfig.subtitleColor)),
                    TextButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onPullRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.35,
                        child: Center(
                          child: Text(
                            'No items at the warehouse yet.',
                            style: TextStyle(color: AppConfig.subtitleColor),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onPullRefresh,
                  child: ListView.builder(
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
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                        initiallyExpanded: false,
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: sel,
                              onChanged: (_) => _toggleSelection(it.id),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TappableNetworkImage(
                                imageUrl: productUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(8),
                                errorWidget: (_, __, ___) => const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Icon(Icons.image_outlined, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: InkWell(
                                onTap: () => _toggleSelection(it.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  child: Text(
                                    it.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Text(
                              it.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                            ),
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
                                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                                  itemBuilder: (ctx, j) => ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: TappableNetworkImage(
                                      imageUrl: receiptUrls[j],
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(6),
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Extra fee: \$${r.additionalFeeAmount.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppConfig.textColor,
                                            ),
                                      ),
                                    ),
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
                              ),
                            ],
                            if (r != null &&
                                r.conditionNotes != null &&
                                r.conditionNotes!.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Notes: ${r.conditionNotes}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Condition / intake notes from the warehouse',
                                    child: Icon(Icons.notes_outlined, size: 18, color: AppConfig.subtitleColor),
                                  ),
                                ],
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
                    );
                  },
                ),
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
                  Builder(
                    builder: (context) {
                      final items = ref.watch(warehouseItemsProvider).valueOrNull ?? [];
                      final t = _selectionTotals(items);
                      if (t.selectedCount == 0) {
                        return const SizedBox.shrink();
                      }
                      final dimText = _selectionDimsSummary(items);
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
                                'Σ weight (est.): ${t.totalWeightLb.toStringAsFixed(2)} lb',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (dimText != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Dimensions (received):',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppConfig.subtitleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dimText,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                                ),
                              ],
                              if (t.extraFees > 0.0001) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Σ extra fees: \$${t.extraFees.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
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
                              ],
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
    final lines = <String>[];
    final wLine = weightLineForItem(
      receiptWeightLb: r?.receivedWeight,
      catalogWeightKg: it.weightKg,
    );
    if (wLine != null) lines.add(wLine);
    if (r != null &&
        r.receivedLength != null &&
        r.receivedWidth != null &&
        r.receivedHeight != null) {
      lines.add(
        'Received size: ${formatReceiptDimsIn(r.receivedLength!, r.receivedWidth!, r.receivedHeight!)}',
      );
    } else if (it.dimensions != null && it.dimensions!.trim().isNotEmpty) {
      lines.add('Listed size (catalog): ${it.dimensions}');
    }
    lines.add('Qty ${it.quantity}');
    return lines.join('\n');
  }
}
