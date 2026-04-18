import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../purchase_assistant/purchase_assistant_list_screen.dart';
import '../purchase_assistant/purchase_assistant_providers.dart';
import '../warehouse/my_warehouse_screen.dart';
import '../warehouse/shipments_tracking_screen.dart';
import '../warehouse/warehouse_providers.dart';
import 'orders_list_screen.dart';
import 'providers/orders_providers.dart';

/// Post-checkout hub: Orders · Purchase Assistant · Warehouse · Shipments.
class PostOrderHubScreen extends ConsumerStatefulWidget {
  const PostOrderHubScreen({super.key, this.initialTabIndex = 0});

  /// Tab index: 0 Orders, 1 Assist, 2 Warehouse, 3 Shipments. Use query `hubTab` on [AppRoutes.orders].
  final int initialTabIndex;

  @override
  ConsumerState<PostOrderHubScreen> createState() => _PostOrderHubScreenState();
}

class _PostOrderHubScreenState extends ConsumerState<PostOrderHubScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  Timer? _tabRefreshDebounce;
  int _lastRefreshedTab = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final idx = widget.initialTabIndex.clamp(0, 3);
    _tabController = TabController(length: 4, vsync: this, initialIndex: idx);
    _tabController.addListener(_onTabControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshTabIndex(_tabController.index, force: true);
    });
  }

  void _onTabControllerTick() {
    if (_tabController.indexIsChanging) return;
    _scheduleRefreshForTab(_tabController.index);
  }

  void _scheduleRefreshForTab(int index) {
    _tabRefreshDebounce?.cancel();
    _tabRefreshDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _refreshTabIndex(index, force: false);
    });
  }

  void _refreshTabIndex(int index, {required bool force}) {
    if (!force && index == _lastRefreshedTab) return;
    _lastRefreshedTab = index;
    switch (index) {
      case 0:
        invalidateStandardOrdersList(ref);
        break;
      case 1:
        invalidatePurchaseAssistantRequests(ref);
        break;
      case 2:
        ref.invalidate(warehouseItemsProvider);
        break;
      case 3:
        ref.invalidate(outboundShipmentsProvider);
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTabIndex(_tabController.index, force: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabRefreshDebounce?.cancel();
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final paAsync = ref.watch(purchaseAssistantRequestsProvider);
    final warehouseAsync = ref.watch(warehouseItemsProvider);
    final shipmentsAsync = ref.watch(outboundShipmentsProvider);

    final ordersCount = ordersAsync.valueOrNull?.length;
    final paCount = paAsync.valueOrNull?.length;
    final warehouseCount = warehouseAsync.valueOrNull?.length;
    final shipmentsCount = shipmentsAsync.valueOrNull?.length;

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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: _TabLabel(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                count: ordersCount,
              ),
            ),
            Tab(
              child: _TabLabel(
                icon: Icons.handshake_outlined,
                label: 'Assist',
                count: paCount,
              ),
            ),
            Tab(
              child: _TabLabel(
                icon: Icons.warehouse_outlined,
                label: 'Warehouse',
                count: warehouseCount,
              ),
            ),
            Tab(
              child: _TabLabel(
                icon: Icons.local_shipping_outlined,
                label: 'Shipments',
                count: shipmentsCount,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrdersListScreen(hubEmbedded: true),
          PurchaseAssistantListScreen(hubEmbedded: true),
          MyWarehouseScreen(hubEmbedded: true),
          ShipmentsTrackingScreen(hubEmbedded: true),
        ],
      ),
    );
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
