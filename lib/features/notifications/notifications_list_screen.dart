import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state_scaffold.dart';
import 'models/notification_item.dart';
import 'providers/notifications_list_provider.dart';

/// Notifications list with filters (All | Orders | Shipments | Promo) and sections.
/// Data from GET /api/notifications.
class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends ConsumerState<NotificationsListScreen> {
  NotificationFilterType _filter = NotificationFilterType.all;

  static List<NotificationItem> _importantFrom(List<NotificationItem> items) =>
      items.where((e) => e.important).toList();
  static List<NotificationItem> _todayFrom(List<NotificationItem> items) =>
      items.where((e) => e.timeAgo.contains('h') || e.timeAgo == 'Now').toList();
  static List<NotificationItem> _yesterdayFrom(List<NotificationItem> items) =>
      items.where((e) => e.timeAgo == 'Yesterday').toList();

  List<NotificationItem> _byFilter(List<NotificationItem> list) {
    switch (_filter) {
      case NotificationFilterType.all:
        return list;
      case NotificationFilterType.orders:
        return list.where((e) => e.type == NotificationFilterType.orders).toList();
      case NotificationFilterType.shipments:
        return list.where((e) => e.type == NotificationFilterType.shipments).toList();
      case NotificationFilterType.promo:
        return list.where((e) => e.type == NotificationFilterType.promo).toList();
    }
  }

  void _markAllRead() {
    ref.invalidate(notificationsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    return notificationsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: const Text('Notifications'),
          centerTitle: true,
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: const Text('Notifications'),
          centerTitle: true,
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (items) => _buildContent(items),
    );
  }

  Widget _buildContent(List<NotificationItem> items) {
    final hasItems = items.isNotEmpty;
    if (!hasItems) {
      return EmptyStateScaffold(
        appBarTitle: 'Notifications',
        showBackButton: true,
        title: "You're all caught up 🎉",
        subtitle:
            "We'll notify you about your orders, shipments, payments, and support updates.",
        primaryButtonLabel: 'Track My Orders',
        onPrimaryPressed: () => context.go(AppRoutes.orders),
      );
    }

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'mark_read') _markAllRead();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'mark_read', child: Text('Mark all as read')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == NotificationFilterType.all,
                    onTap: () =>
                        setState(() => _filter = NotificationFilterType.all),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Orders',
                    selected: _filter == NotificationFilterType.orders,
                    onTap: () =>
                        setState(() => _filter = NotificationFilterType.orders),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Shipments',
                    selected: _filter == NotificationFilterType.shipments,
                    onTap: () =>
                        setState(() => _filter = NotificationFilterType.shipments),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Promo',
                    selected: _filter == NotificationFilterType.promo,
                    onTap: () =>
                        setState(() => _filter = NotificationFilterType.promo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationsListProvider);
                  await ref.read(notificationsListProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    ..._buildSection('IMPORTANT', _byFilter(_importantFrom(items)), true),
                    ..._buildSection('TODAY', _byFilter(_todayFrom(items)), false),
                    ..._buildSection('YESTERDAY', _byFilter(_yesterdayFrom(items)), false),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(
      String header, List<NotificationItem> list, bool isImportant) {
    if (list.isEmpty) return [];
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            header,
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          if (header == 'TODAY')
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all as read',
                style: AppTextStyles.bodySmall(AppConfig.primaryColor),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ...list.map((e) => _NotificationCard(item: e, isImportant: isImportant)),
      const SizedBox(height: AppSpacing.lg),
    ];
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppConfig.primaryColor
          : AppConfig.borderColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: AppTextStyles.bodySmall(
              selected ? Colors.white : AppConfig.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.isImportant});

  final NotificationItem item;
  final bool isImportant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isImportant
              ? Colors.amber.withValues(alpha: 0.15)
              : AppConfig.cardColor,
          border: Border.all(
            color: isImportant
                ? Colors.amber.withValues(alpha: 0.5)
                : AppConfig.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconForType(item.type),
                  size: 24,
                  color: isImportant ? Colors.amber.shade800 : AppConfig.subtitleColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!item.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppConfig.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.titleMedium(AppConfig.textColor),
                      ),
                      Text(
                        item.subtitle,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                      Text(
                        item.timeAgo,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                      if (item.actionLabel != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            item.actionLabel!,
                            style: AppTextStyles.label(AppConfig.primaryColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(NotificationFilterType type) {
    switch (type) {
      case NotificationFilterType.orders:
        return Icons.shopping_bag_outlined;
      case NotificationFilterType.shipments:
        return Icons.local_shipping_outlined;
      case NotificationFilterType.promo:
        return Icons.local_offer_outlined;
      case NotificationFilterType.all:
        return Icons.notifications_outlined;
    }
  }
}
