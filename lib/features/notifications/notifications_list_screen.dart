import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state_scaffold.dart';
import 'models/notification_item.dart';

/// Notifications list with filters (All | Orders | Shipments | Promo) and sections
/// IMPORTANT, TODAY, YESTERDAY. Shows empty state when no items.
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  NotificationFilterType _filter = NotificationFilterType.all;
  late List<NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _mockNotifications();
  }

  static List<NotificationItem> _mockNotifications() {
    return [
      const NotificationItem(
        id: '1',
        type: NotificationFilterType.shipments,
        title: 'Customs Issue: Package #ZY-9902',
        subtitle: 'Action required. Please provide additional details to clear your package.',
        timeAgo: 'Now',
        read: false,
        important: true,
        actionLabel: 'Resolve Now',
        actionRoute: null,
      ),
      const NotificationItem(
        id: '2',
        type: NotificationFilterType.shipments,
        title: 'Shipment Out for Delivery',
        subtitle: 'Order #ZY-9901 is out for delivery today.',
        timeAgo: '2h ago',
        read: false,
      ),
      const NotificationItem(
        id: '3',
        type: NotificationFilterType.orders,
        title: 'Order Confirmed',
        subtitle: 'Your order #ZY-9903 has been confirmed.',
        timeAgo: '5h ago',
        read: false,
      ),
      const NotificationItem(
        id: '4',
        type: NotificationFilterType.promo,
        title: 'Price Drop Alert',
        subtitle: 'Items in your wishlist have dropped in price.',
        timeAgo: 'Yesterday',
        read: true,
      ),
      const NotificationItem(
        id: '5',
        type: NotificationFilterType.shipments,
        title: 'Monthly Logistics Summary',
        subtitle: 'Your January shipping summary is ready.',
        timeAgo: 'Yesterday',
        read: true,
      ),
    ];
  }

  List<NotificationItem> get _important =>
      _items.where((e) => e.important).toList();
  List<NotificationItem> get _today =>
      _items.where((e) => e.timeAgo.contains('h') || e.timeAgo == 'Now').toList();
  List<NotificationItem> get _yesterday =>
      _items.where((e) => e.timeAgo == 'Yesterday').toList();

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
    setState(() {
      _items = _items.map((e) => NotificationItem(
            id: e.id,
            type: e.type,
            title: e.title,
            subtitle: e.subtitle,
            timeAgo: e.timeAgo,
            read: true,
            important: e.important,
            actionLabel: e.actionLabel,
            actionRoute: e.actionRoute,
          )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  ..._buildSection('IMPORTANT', _byFilter(_important), true),
                  ..._buildSection('TODAY', _byFilter(_today), false),
                  ..._buildSection('YESTERDAY', _byFilter(_yesterday), false),
                  const SizedBox(height: AppSpacing.xxl),
                ],
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
