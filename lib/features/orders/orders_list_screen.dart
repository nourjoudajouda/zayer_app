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
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppConfig.radiusMedium)),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _SectionTitle(title: 'Status'),
            _SheetOption(
              label: 'All',
              isSelected: statusFilter == OrdersFilter.all,
              onTap: () { onStatusChanged(OrdersFilter.all); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'In Progress',
              isSelected: statusFilter == OrdersFilter.inProgress,
              onTap: () { onStatusChanged(OrdersFilter.inProgress); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Delivered',
              isSelected: statusFilter == OrdersFilter.delivered,
              onTap: () { onStatusChanged(OrdersFilter.delivered); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Cancelled',
              isSelected: statusFilter == OrdersFilter.cancelled,
              onTap: () { onStatusChanged(OrdersFilter.cancelled); Navigator.of(ctx).pop(); },
            ),
            _SectionTitle(title: 'Origin'),
            _SheetOption(
              label: 'All origins',
              isSelected: originFilter == OrdersOriginFilter.all,
              onTap: () { onOriginChanged(OrdersOriginFilter.all); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'USA',
              isSelected: originFilter == OrdersOriginFilter.usa,
              onTap: () { onOriginChanged(OrdersOriginFilter.usa); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Turkey',
              isSelected: originFilter == OrdersOriginFilter.turkey,
              onTap: () { onOriginChanged(OrdersOriginFilter.turkey); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Multi-origin',
              isSelected: originFilter == OrdersOriginFilter.multiOrigin,
              onTap: () { onOriginChanged(OrdersOriginFilter.multiOrigin); Navigator.of(ctx).pop(); },
            ),
            _SectionTitle(title: 'Sort by'),
            _SheetOption(
              label: 'Newest first',
              isSelected: sortOption == OrdersSortOption.newestFirst,
              onTap: () { onSortChanged(OrdersSortOption.newestFirst); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Oldest first',
              isSelected: sortOption == OrdersSortOption.oldestFirst,
              onTap: () { onSortChanged(OrdersSortOption.oldestFirst); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Amount: High to low',
              isSelected: sortOption == OrdersSortOption.amountHighToLow,
              onTap: () { onSortChanged(OrdersSortOption.amountHighToLow); Navigator.of(ctx).pop(); },
            ),
            _SheetOption(
              label: 'Amount: Low to high',
              isSelected: sortOption == OrdersSortOption.amountLowToHigh,
              onTap: () { onSortChanged(OrdersSortOption.amountLowToHigh); Navigator.of(ctx).pop(); },
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
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
  const _SheetOption({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: AppConfig.primaryColor, size: 22) : null,
      selected: isSelected,
      selectedTileColor: AppConfig.primaryColor.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}

/// Orders list screen. Route: /orders (tab in shell).
/// Design: back, title, filter icon; pills All | In Progress | Delivered | Cancelled; cards with origin flags, status, map (in transit), actions.
class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final filterAsync = ref.watch(filteredOrdersProvider);
    final statusFilter = ref.watch(ordersFilterProvider);
    final originFilter = ref.watch(ordersOriginFilterProvider);
    final sortOption = ref.watch(ordersSortProvider);

    return ordersAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (allOrders) {
        if (allOrders.isEmpty) {
          return const OrdersEmptyScreen();
        }
        return filterAsync.when(
          data: (filteredOrders) => _OrdersListContent(
            orders: filteredOrders,
            activeFilter: statusFilter,
            originFilter: originFilter,
            sortOption: sortOption,
            onFilterChanged: (f) => ref.read(ordersFilterProvider.notifier).state = f,
            onOriginChanged: (f) => ref.read(ordersOriginFilterProvider.notifier).state = f,
            onSortChanged: (s) => ref.read(ordersSortProvider.notifier).state = s,
          ),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Orders')), body: Center(child: Text('Error: $e'))),
        );
      },
    );
  }
}

class _OrdersListContent extends StatelessWidget {
  const _OrdersListContent({
    required this.orders,
    required this.activeFilter,
    required this.originFilter,
    required this.sortOption,
    required this.onFilterChanged,
    required this.onOriginChanged,
    required this.onSortChanged,
  });

  final List<OrderModel> orders;
  final OrdersFilter activeFilter;
  final OrdersOriginFilter originFilter;
  final OrdersSortOption sortOption;
  final ValueChanged<OrdersFilter> onFilterChanged;
  final ValueChanged<OrdersOriginFilter> onOriginChanged;
  final ValueChanged<OrdersSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
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
            icon: Icon(Icons.tune, color: AppConfig.textColor),
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
            _OrdersFilterPills(
              selected: activeFilter,
              onSelected: onFilterChanged,
            ),
            Expanded(
              child: orders.isEmpty
                  ? _FilterEmptyState(activeFilter: activeFilter)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OrderCard(order: orders[index]),
                        );
                      },
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
      case OrdersFilter.inProgress:
        return 'No orders in progress';
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
            Icon(Icons.inbox_outlined, size: 64, color: AppConfig.subtitleColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              _message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppConfig.subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersFilterPills extends StatelessWidget {
  const _OrdersFilterPills({
    required this.selected,
    required this.onSelected,
  });

  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Pill(label: 'All', isSelected: selected == OrdersFilter.all, onTap: () => onSelected(OrdersFilter.all)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(label: 'In Progress', isSelected: selected == OrdersFilter.inProgress, onTap: () => onSelected(OrdersFilter.inProgress)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(label: 'Delivered', isSelected: selected == OrdersFilter.delivered, onTap: () => onSelected(OrdersFilter.delivered)),
          const SizedBox(width: AppSpacing.sm),
          _Pill(label: 'Cancelled', isSelected: selected == OrdersFilter.cancelled, onTap: () => onSelected(OrdersFilter.cancelled)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppConfig.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isSelected ? null : Border.all(color: AppConfig.borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppConfig.subtitleColor,
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
      case OrderStatus.inTransit:
        return AppConfig.primaryColor;
      case OrderStatus.delivered:
        return AppConfig.successGreen;
      case OrderStatus.cancelled:
        return AppConfig.subtitleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placedText = order.placedDate.toLowerCase().startsWith('placed')
        ? order.placedDate
        : 'Placed on ${order.placedDate}';

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
              _OriginFlags(origin: order.origin),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  order.originLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.subtitleColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          if (order.status == OrderStatus.inTransit && order.estimatedDelivery != null) ...[
            const SizedBox(height: AppSpacing.md),
            _MapPlaceholder(),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: 'Estimated Delivery',
              value: _formatEstimatedDelivery(order.estimatedDelivery!),
              valueColor: AppConfig.primaryColor,
            ),
          ],
          if (order.status == OrderStatus.delivered && order.deliveredOn != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: 'Delivered On', value: _stripDelivered(order.deliveredOn!), valueColor: null),
          ],
          if (order.status == OrderStatus.cancelled && order.refundStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: 'Refund Status', value: order.refundStatus!, valueColor: AppConfig.successGreen),
          ],
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Total Amount', value: order.totalAmount, valueColor: null),
          const SizedBox(height: AppSpacing.md),
          _ActionButtons(order: order),
        ],
      ),
    );
  }

  static String _formatEstimatedDelivery(String s) {
    if (s.toLowerCase().startsWith('est.')) return s.replaceFirst(RegExp(r'^[Ee]st\.\s*'), '').trim();
    return s;
  }

  static String _stripDelivered(String s) {
    if (s.toLowerCase().startsWith('delivered ')) return s.substring(9).trim();
    return s;
  }
}

class _OriginFlags extends StatelessWidget {
  const _OriginFlags({required this.origin});

  final OrderOrigin origin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (origin == OrderOrigin.usa || origin == OrderOrigin.multiOrigin) _FlagEmoji('🇺🇸'),
        if (origin == OrderOrigin.multiOrigin) const SizedBox(width: 2),
        if (origin == OrderOrigin.turkey || origin == OrderOrigin.multiOrigin) _FlagEmoji('🇹🇷'),
      ],
    );
  }
}

class _FlagEmoji extends StatelessWidget {
  const _FlagEmoji(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 18));
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.public, size: 56, color: AppConfig.primaryColor.withValues(alpha: 0.4)),
          Positioned(
            right: 24,
            top: 24,
            child: Icon(Icons.location_on, color: Colors.red.shade400, size: 28),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? AppConfig.textColor,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
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
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConfig.subtitleColor,
            side: BorderSide(color: AppConfig.borderColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
          ),
          child: const Text('View Details'),
        ),
      );
    }

    if (order.status == OrderStatus.inTransit) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => context.push('${AppRoutes.orderTracking}/${order.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
              ),
              child: const Text('Track Order'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.subtitleColor,
                side: BorderSide(color: AppConfig.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.delivered) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.markets),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.subtitleColor,
                side: BorderSide(color: AppConfig.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
              ),
              child: const Text('Buy Again'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('${AppRoutes.orderDetail}/${order.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.subtitleColor,
                side: BorderSide(color: AppConfig.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
