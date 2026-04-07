import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import 'models/warehouse_models.dart';
import 'warehouse_api.dart';

/// Lists outbound shipments (status, tracking, box photo).
class ShipmentsTrackingScreen extends StatefulWidget {
  const ShipmentsTrackingScreen({super.key});

  @override
  State<ShipmentsTrackingScreen> createState() => _ShipmentsTrackingScreenState();
}

class _ShipmentsTrackingScreenState extends State<ShipmentsTrackingScreen> {
  late Future<List<OutboundShipmentApi>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchShipments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
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
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final s = list[i];
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
                        if (s.carrier != null && s.carrier!.isNotEmpty)
                          Text('Carrier: ${s.carrier}', style: TextStyle(color: AppConfig.subtitleColor)),
                        if (s.trackingNumber != null && s.trackingNumber!.isNotEmpty)
                          Text('Tracking: ${s.trackingNumber}', style: TextStyle(color: AppConfig.subtitleColor)),
                        Text(
                          'Shipping paid: \$${s.totalShippingPayment.toStringAsFixed(2)} ${s.currency}',
                          style: Theme.of(context).textTheme.bodySmall,
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
                        ...s.items.map(
                          (it) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: it.imageUrl != null && it.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: it.imageUrl!.startsWith('http')
                                              ? it.imageUrl!
                                              : '${ApiClient.safeBaseUrl ?? ''}${it.imageUrl}',
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, size: 20),
                                        )
                                      : const Icon(Icons.image_outlined, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${it.name} × ${it.quantity}')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
