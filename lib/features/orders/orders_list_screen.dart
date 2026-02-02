import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import 'models/order_model.dart';
import 'orders_empty_screen.dart';
import 'providers/orders_providers.dart';

/// Orders list screen. Route: /orders (tab in shell).
/// API will plug in: GET /api/orders with ?status= filter later.
class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterAsync = ref.watch(filteredOrdersProvider);

    return filterAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return const OrdersEmptyScreen();
        }
        return _OrdersListContent(orders: orders);
      },
    );
  }
}

class _OrdersListContent extends ConsumerWidget {
  const _OrdersListContent({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(ordersFilterProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppConfig.textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _OrdersSegmentedTabs(
              selected: filter,
              onSelected: (f) =>
                  ref.read(ordersFilterProvider.notifier).state = f,
            ),
            Expanded(
              child: ListView.builder(
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

class _OrdersSegmentedTabs extends StatelessWidget {
  const _OrdersSegmentedTabs({
    required this.selected,
    required this.onSelected,
  });

  final OrdersFilter selected;
  final ValueChanged<OrdersFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabChip(
              label: 'All',
              isSelected: selected == OrdersFilter.all,
              onTap: () => onSelected(OrdersFilter.all),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TabChip(
              label: 'In Progress',
              isSelected: selected == OrdersFilter.inProgress,
              onTap: () => onSelected(OrdersFilter.inProgress),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TabChip(
              label: 'Delivered',
              isSelected: selected == OrdersFilter.delivered,
              onTap: () => onSelected(OrdersFilter.delivered),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TabChip(
              label: 'Cancelled',
              isSelected: selected == OrdersFilter.cancelled,
              onTap: () => onSelected(OrdersFilter.cancelled),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
      color: isSelected ? AppConfig.primaryColor : AppConfig.cardColor,
      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppConfig.primaryColor : AppConfig.borderColor,
            ),
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final statusColor = order.status == OrderStatus.inTransit
        ? AppConfig.primaryColor
        : order.status == OrderStatus.delivered
            ? AppConfig.successGreen
            : AppConfig.subtitleColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppConfig.borderColor.withValues(alpha: 0.3),
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
              Text(
                order.originLabel,
                style: AppTextStyles.label(AppConfig.subtitleColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.statusLabel,
                  style: AppTextStyles.bodySmall(statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.orderNumber,
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.placedDate,
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              ),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppConfig.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.estimatedDelivery!,
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          ],
          if (order.deliveredOn != null)
            Text(
              order.deliveredOn!,
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
          if (order.refundStatus != null)
            Text(
              order.refundStatus!,
              style: AppTextStyles.bodySmall(AppConfig.successGreen),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Total: ${order.totalAmount}',
            style: AppTextStyles.titleMedium(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (order.canTrack)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
              if (order.canTrack) const SizedBox(width: AppSpacing.sm),
              if (order.canBuyAgain) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.markets),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                    ),
                    child: const Text('Buy Again'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: order.status == OrderStatus.cancelled ? null : () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: order.status == OrderStatus.cancelled
                        ? AppConfig.subtitleColor
                        : AppConfig.textColor,
                    side: BorderSide(
                      color: order.status == OrderStatus.cancelled
                          ? AppConfig.borderColor
                          : AppConfig.borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
