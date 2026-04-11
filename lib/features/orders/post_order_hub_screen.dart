import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../warehouse/my_warehouse_screen.dart';
import '../warehouse/shipments_tracking_screen.dart';
import '../warehouse/warehouse_api.dart';
import 'orders_list_screen.dart';
import 'providers/orders_providers.dart';

/// Post-checkout hub: Orders · Warehouse · Shipments (single entry from shell).
class PostOrderHubScreen extends ConsumerStatefulWidget {
  const PostOrderHubScreen({super.key});

  @override
  ConsumerState<PostOrderHubScreen> createState() => _PostOrderHubScreenState();
}

class _PostOrderHubScreenState extends ConsumerState<PostOrderHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final ordersCount = ordersAsync.valueOrNull?.length;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('My purchases'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: AppConfig.subtitleColor,
          indicatorColor: AppConfig.primaryColor,
          tabs: [
            Tab(
              child: _TabLabel(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                count: ordersCount,
              ),
            ),
            Tab(
              child: FutureBuilder<int>(
                future: _warehouseCount(),
                builder: (context, snap) {
                  return _TabLabel(
                    icon: Icons.warehouse_outlined,
                    label: 'Warehouse',
                    count: snap.data,
                  );
                },
              ),
            ),
            Tab(
              child: FutureBuilder<int>(
                future: _shipmentsCount(),
                builder: (context, snap) {
                  return _TabLabel(
                    icon: Icons.local_shipping_outlined,
                    label: 'Shipments',
                    count: snap.data,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrdersListScreen(hubEmbedded: true),
          MyWarehouseScreen(hubEmbedded: true),
          ShipmentsTrackingScreen(hubEmbedded: true),
        ],
      ),
    );
  }

  Future<int> _warehouseCount() async {
    try {
      final items = await fetchWarehouseItems();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _shipmentsCount() async {
    try {
      final list = await fetchShipments();
      return list.length;
    } catch (_) {
      return 0;
    }
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    this.count,
  });

  final IconData icon;
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final n = count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            n != null ? '$label ($n)' : label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
