import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/order_model.dart';
import 'orders_empty_screen.dart';
import 'providers/orders_providers.dart';

void _showFilterSheet(
  BuildContext context, {
  required OrdersFilter statusFilter,
  required OrdersOriginFilter originFilter,
  required OrdersSortOption sortOption,
  required ValueChanged<OrdersFilter> onStatusChanged,
  required ValueChanged<OrdersOriginFilter> onOriginChanged,
  required ValueChanged<OrdersSortOption> onSortChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppConfig.cardColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppConfig.radiusMedium),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Filter & sort',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _SectionTitle(title: 'Status'),
            _SheetOption(
              label: 'All',
              isSelected: statusFilter == OrdersFilter.all,
              onTap: () {
                onStatusChanged(OrdersFilter.all);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Awaiting review',
              isSelected: statusFilter == OrdersFilter.awaitingReview,
              onTap: () {
                onStatusChanged(OrdersFilter.awaitingReview);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'In execution',
              isSelected: statusFilter == OrdersFilter.inExecution,
              onTap: () {
                onStatusChanged(OrdersFilter.inExecution);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Delivered',
              isSelected: statusFilter == OrdersFilter.delivered,
              onTap: () {
                onStatusChanged(OrdersFilter.delivered);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Cancelled',
              isSelected: statusFilter == OrdersFilter.cancelled,
              onTap: () {
                onStatusChanged(OrdersFilter.cancelled);
                Navigator.of(ctx).pop();
              },
            ),
            _SectionTitle(title: 'Origin'),
            _SheetOption(
              label: 'All origins',
              isSelected: originFilter == OrdersOriginFilter.all,
              onTap: () {
                onOriginChanged(OrdersOriginFilter.all);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'USA',
              isSelected: originFilter == OrdersOriginFilter.usa,
              onTap: () {
                onOriginChanged(OrdersOriginFilter.usa);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Turkey',
              isSelected: originFilter == OrdersOriginFilter.turkey,
              onTap: () {
                onOriginChanged(OrdersOriginFilter.turkey);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Multi-origin',
              isSelected: originFilter == OrdersOriginFilter.multiOrigin,
              onTap: () {
                onOriginChanged(OrdersOriginFilter.multiOrigin);
                Navigator.of(ctx).pop();
              },
            ),
            _SectionTitle(title: 'Sort by'),
            _SheetOption(
              label: 'Newest first',
              isSelected: sortOption == OrdersSortOption.newestFirst,
              onTap: () {
                onSortChanged(OrdersSortOption.newestFirst);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Oldest first',
              isSelected: sortOption == OrdersSortOption.oldestFirst,
              onTap: () {
                onSortChanged(OrdersSortOption.oldestFirst);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Amount: High to low',
              isSelected: sortOption == OrdersSortOption.amountHighToLow,
              onTap: () {
                onSortChanged(OrdersSortOption.amountHighToLow);
                Navigator.of(ctx).pop();
              },
            ),
            _SheetOption(
              label: 'Amount: Low to high',
              isSelected: sortOption == OrdersSortOption.amountLowToHigh,
              onTap: () {
                onSortChanged(OrdersSortOption.amountLowToHigh);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        4,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppConfig.subtitleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: AppConfig.primaryColor, size: 22)
          : null,
      selected: isSelected,
      selectedTileColor: AppConfig.primaryColor.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}

/// Orders list screen. Route: /orders (tab in shell) or embedded in [PostOrderHubScreen].
/// Design: back, title, filter icon; execution-aligned pills; cards with origin flags, status, map (in transit), actions.
class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key, this.hubEmbedded = false});

  /// When true, omits app bar back/home; hub provides outer navigation.
  final bool hubEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final filterAsync = ref.watch(filteredOrdersProvider);
    final statusFilter = ref.watch(ordersFilterProvider);
    final originFilter = ref.watch(ordersOriginFilterProvider);
    final sortOption = ref.watch(ordersSortProvider);

    return ordersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (allOrders) {
        if (allOrders.isEmpty) {
          if (hubEmbedded) {
            return Scaffold(
              backgroundColor: AppConfig.backgroundColor,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No orders yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                  ),
                ),
              ),
            );
          }
          return const OrdersEmptyScreen();
        }
        return filterAsync.when(
          data: (filteredOrders) => _OrdersListContent(
            hubEmbedded: hubEmbedded,
            orders: filteredOrders,
            activeFilter: statusFilter,
            originFilter: originFilter,
            sortOption: sortOption,
            onRefresh: () async {
              ref.invalidate(ordersProvider);
              await ref.read(ordersProvider.future);
            },
            onFilterChanged: (f) =>
                ref.read(ordersFilterProvider.notifier).state = f,
            onOriginChanged: (f) =>
                ref.read(ordersOriginFilterProvider.notifier).state = f,
            onSortChanged: (s) =>
                ref.read(ordersSortProvider.notifier).state = s,
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Orders')),
            body: Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }
}

class _OrdersListContent extends StatelessWidget {
  const _OrdersListContent({
    required this.hubEmbedded,
    required this.orders,
    required this.activeFilter,
    required this.originFilter,
    required this.sortOption,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.onOriginChanged,
    required this.onSortChanged,
  });

  final bool hubEmbedded;
  final List<OrderModel> orders;
  final OrdersFilter activeFilter;
  final OrdersOriginFilter originFilter;
  final OrdersSortOption sortOption;
  final Future<void> Function() onRefresh;
  final ValueChanged<OrdersFilter> onFilterChanged;
  final ValueChanged<OrdersOriginFilter> onOriginChanged;
  final ValueChanged<OrdersSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: hubEmbedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(AppRoutes.home),
              ),
              title: const Text('Orders'),
              centerTitle: true,
              backgroundColor: AppConfig.backgroundColor,
              foregroundColor: AppConfig.textColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: AppConfig.primaryColor,
                  ),
                  onPressed: () => _showFilterSheet(
                    context,
                    statusFilter: activeFilter,
                    originFilter: originFilter,
                    sortOption: sortOption,
                    onStatusChanged: onFilterChanged,
                    onOriginChanged: onOriginChanged,
                    onSortChanged: onSortChanged,
                  ),
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (hubEmbedded)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.tune_rounded, color: AppConfig.primaryColor),
                  onPressed: () => _showFilterSheet(
                    context,
                    statusFilter: activeFilter,
                    originFilter: originFilter,
                    sortOption: sortOption,
                    onStatusChanged: onFilterChanged,
                    onOriginChanged: onOriginChanged,
                    onSortChanged: onSortChanged,
                  ),
                ),
              ),
            _OrdersFilterPills(
              selected: activeFilter,
              onSelected: onFilterChanged,
            ),
            Expanded(
              child: orders.isEmpty
                  ? _FilterEmptyState(activeFilter: activeFilter)
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _OrderCard(order: orders[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.activeFilter});

  final OrdersFilter activeFilter;

  String get _message {
    switch (activeFilter) {
      case OrdersFilter.awaitingReview:
        return 'No orders awaiting review';
      case OrdersFilter.inExecution:
        return 'No orders in execution';
      case OrdersFilter.delivered:
        return 'No delivered orders';
      case OrdersFilter.cancelled:
        return 'No cancelled orders';
      case OrdersFilter.all:
        return 'No orders';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppConfig.subtitleColor,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppConfig.subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersFilterPills extends StatelessWidget {
  const _OrdersFilterPills({required this.selected, required this.onSelected});

  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _Pill(
            label: 'All',
            isSelected: selected == OrdersFilter.all,
            onTap: () => onSelected(OrdersFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: 'Review',
            isSelected: selected == OrdersFilter.awaitingReview,
            onTap: () => onSelected(OrdersFilter.awaitingReview),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: 'Active',
            isSelected: selected == OrdersFilter.inExecution,
            onTap: () => onSelected(OrdersFilter.inExecution),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: 'Delivered',
            isSelected: selected == OrdersFilter.delivered,
            onTap: () => onSelected(OrdersFilter.delivered),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Pill(
            label: 'Cancelled',
            isSelected: selected == OrdersFilter.cancelled,
            onTap: () => onSelected(OrdersFilter.cancelled),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppConfig.primaryColor : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? AppConfig.primaryColor
                  : const Color(0xFFF3F4F6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppConfig.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  Color get _statusColor {
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

  bool get _isTransitLike =>
      order.status == OrderStatus.inTransit ||
      order.status == OrderStatus.shipped;
  bool get _isDelivered => order.status == OrderStatus.delivered;
  bool get _isCancelled => order.status == OrderStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final placedText = order.placedOnLine;
    final orderImage = _firstShipmentImage();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _OriginTag(origin: order.origin),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _countryTrail(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusChipLabel(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Order ${order.orderNumber}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppConfig.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            placedText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          if (_isTransitLike) ...[
            const SizedBox(height: AppSpacing.md),
            _TransitRouteRow(),
            const SizedBox(height: AppSpacing.sm),
            _TotalEtaRow(
              total: order.totalAmount,
              eta: order.estimatedDelivery != null
                  ? _formatEstimatedDelivery(order.estimatedDelivery!)
                  : 'TBD',
            ),
          ],
          if (_isDelivered && orderImage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DeliveredImageBanner(imageUrl: orderImage),
          ],
          if (_isDelivered) ...[
            const SizedBox(height: AppSpacing.sm),
            _SimpleTotalRow(total: order.totalAmount),
          ],
          if (_isCancelled) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.refundStatus ??
                  'Full refund processed to original payment method.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ActionButtons(order: order),
        ],
      ),
    );
  }

  static String _formatEstimatedDelivery(String s) {
    if (s.toLowerCase().startsWith('est.')) {
      return s.replaceFirst(RegExp(r'^[Ee]st\.\s*'), '').trim();
    }
    return s;
  }

  String _countryTrail() {
    return switch (order.origin) {
      OrderOrigin.multiOrigin => 'USA • TR',
      OrderOrigin.usa => 'USA',
      OrderOrigin.turkey => 'TR',
    };
  }

  String _statusChipLabel() => order.statusChipUpper;

  String? _firstShipmentImage() {
    for (final s in order.shipments) {
      for (final item in s.items) {
        final url = item.imageUrl;
        if (url != null && url.trim().isNotEmpty) return url;
      }
    }
    return null;
  }
}

class _OriginTag extends StatelessWidget {
  const _OriginTag({required this.origin});

  final OrderOrigin origin;

  @override
  Widget build(BuildContext context) {
    final label = switch (origin) {
      OrderOrigin.multiOrigin => 'MULTI-ORIGIN',
      OrderOrigin.usa => 'USA',
      OrderOrigin.turkey => 'TR',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppConfig.primaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TransitRouteRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inactive = AppConfig.borderColor;
    return Row(
      children: [
        Icon(
          Icons.flight_takeoff_rounded,
          color: AppConfig.primaryColor,
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 2,
            color: AppConfig.primaryColor.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.hub_rounded, color: AppConfig.primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 2, color: inactive)),
        const SizedBox(width: 8),
        Icon(Icons.home_rounded, color: inactive, size: 16),
      ],
    );
  }
}

class _TotalEtaRow extends StatelessWidget {
  const _TotalEtaRow({required this.total, required this.eta});

  final String total;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL & ETA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppConfig.subtitleColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total • $eta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppConfig.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleTotalRow extends StatelessWidget {
  const _SimpleTotalRow({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppConfig.subtitleColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveredImageBanner extends StatelessWidget {
  const _DeliveredImageBanner({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
      child: Image.network(
        imageUrl,
        height: 96,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
            gradient: const LinearGradient(
              colors: [Color(0xFF3C8E90), Color(0xFF1F6AA5)],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
          child: const Text(
            'Support Center',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (order.canTrack) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  context.push('${AppRoutes.orderDetail}/${order.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.textColor,
                backgroundColor: const Color(0xFFF9FAFB),
                side: BorderSide(color: AppConfig.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
              ),
              child: const Text('Details'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: () =>
                  context.push('${AppRoutes.orderTracking}/${order.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
              ),
              child: const Text('Track'),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.delivered) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConfig.textColor,
            backgroundColor: const Color(0xFFF9FAFB),
            side: BorderSide(color: AppConfig.borderColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
          ),
          child: const Text('View Details'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.textColor,
          backgroundColor: const Color(0xFFF9FAFB),
          side: BorderSide(color: AppConfig.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          ),
        ),
        child: const Text('View Details'),
      ),
    );
  }
}
