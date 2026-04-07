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
  const MyWarehouseScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
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
                    final url = it.imageUrl != null && it.imageUrl!.isNotEmpty
                        ? (it.imageUrl!.startsWith('http')
                            ? it.imageUrl!
                            : '${ApiClient.safeBaseUrl ?? ''}${it.imageUrl}')
                        : null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: CheckboxListTile(
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
                        secondary: SizedBox(
                          width: 56,
                          height: 56,
                          child: url != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.image_outlined),
                                  ),
                                )
                              : const Icon(Icons.image_outlined),
                        ),
                        title: Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          _subtitle(it),
                          style: TextStyle(fontSize: 12, color: AppConfig.subtitleColor),
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
              child: FilledButton(
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
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(WarehouseItemApi it) {
    final r = it.receipt;
    final w = r?.receivedWeight ?? it.weightKg;
    final parts = <String>[];
    if (w != null) parts.add('${w.toStringAsFixed(2)} kg');
    if (r != null &&
        r.receivedLength != null &&
        r.receivedWidth != null &&
        r.receivedHeight != null) {
      parts.add(
        '${r.receivedLength!.toStringAsFixed(0)}×${r.receivedWidth!.toStringAsFixed(0)}×${r.receivedHeight!.toStringAsFixed(0)} cm',
      );
    }
    if (parts.isEmpty) return 'Qty ${it.quantity}';
    return '${parts.join(' · ')} · qty ${it.quantity}';
  }
}
