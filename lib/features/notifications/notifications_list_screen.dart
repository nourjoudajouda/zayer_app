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
import 'providers/notifications_state_provider.dart';
import 'repositories/notifications_repository.dart';
import 'utils/notification_action_route_resolver.dart';

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
  final NotificationsRepository _repo = NotificationsRepositoryImpl();

  static List<NotificationItem> _importantFrom(List<NotificationItem> items) =>
      items.where((e) => e.important).toList();
  static List<NotificationItem> _todayFrom(List<NotificationItem> items) =>
      items
          .where((e) => e.timeAgo.contains('h') || e.timeAgo == 'Now')
          .toList();
  static List<NotificationItem> _yesterdayFrom(List<NotificationItem> items) =>
      items.where((e) => e.timeAgo == 'Yesterday').toList();

  List<NotificationItem> _byFilter(List<NotificationItem> list) {
    switch (_filter) {
      case NotificationFilterType.all:
        return list;
      case NotificationFilterType.orders:
        return list
            .where((e) => e.type == NotificationFilterType.orders)
            .toList();
      case NotificationFilterType.shipments:
        return list
            .where((e) => e.type == NotificationFilterType.shipments)
            .toList();
      case NotificationFilterType.payments:
        return list
            .where((e) => e.type == NotificationFilterType.payments)
            .toList();
      case NotificationFilterType.promo:
        return list
            .where((e) => e.type == NotificationFilterType.promo)
            .toList();
    }
  }

  Future<void> _markAllRead(List<NotificationItem> items) async {
    final ids = items.map((e) => e.id);
    ref.read(locallyReadNotificationIdsProvider.notifier).markAllRead(ids);
    // Best-effort backend call; do not block UI.
    try {
      await _repo.markAllRead();
    } catch (_) {}
    ref.invalidate(notificationsListProvider);
  }

  Future<void> _delete(NotificationItem item) async {
    // Hide immediately for snappy UX.
    ref
        .read(locallyDeletedNotificationIdsProvider.notifier)
        .markDeleted(item.id);
    // Best-effort backend call.
    try {
      await _repo.delete(item.id);
    } catch (_) {}
    ref.invalidate(notificationsListProvider);
  }

  void _openNotification(NotificationItem item) {
    // Update local read state immediately for better UX.
    if (!item.read) {
      ref.read(locallyReadNotificationIdsProvider.notifier).markRead(item.id);
      // Best-effort backend update.
      _repo.markRead(item.id);
    }

    final route = _routeForItem(item)?.trim();
    if (route == null || route.isEmpty) {
      if (context.mounted) context.go(AppRoutes.notifications);
      return;
    }
    if (context.mounted) context.go(route);
  }

  String? _routeForItem(NotificationItem item) {
    return resolveNotificationActionRoute(item.actionRoute);
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Notification settings',
            onPressed: () => context.push(AppRoutes.notificationSettings),
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
                    onTap: () => setState(
                      () => _filter = NotificationFilterType.shipments,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Promo',
                    selected: _filter == NotificationFilterType.promo,
                    onTap: () =>
                        setState(() => _filter = NotificationFilterType.promo),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Payments',
                    selected: _filter == NotificationFilterType.payments,
                    onTap: () => setState(
                      () => _filter = NotificationFilterType.payments,
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: [
                    ..._buildSection(
                      'IMPORTANT',
                      _byFilter(_importantFrom(items)),
                      true,
                    ),
                    ..._buildSection(
                      'TODAY',
                      _byFilter(_todayFrom(items)),
                      false,
                    ),
                    ..._buildSection(
                      'YESTERDAY',
                      _byFilter(_yesterdayFrom(items)),
                      false,
                    ),
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
    String header,
    List<NotificationItem> list,
    bool isImportant,
  ) {
    if (list.isEmpty) return [];
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            header,
            style: AppTextStyles.bodySmall(
              AppConfig.subtitleColor,
            ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.3),
          ),
          if (header == 'TODAY')
            TextButton(
              onPressed: () => _markAllRead(list),
              child: Text(
                'Mark all as read',
                style: AppTextStyles.bodySmall(
                  AppConfig.primaryColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      ...list.map(
        (e) => _NotificationCard(
          item: e,
          isImportant: isImportant,
          onTap: () => _openNotification(e),
          onDelete: () => _delete(e),
          onMarkRead: () {
            ref
                .read(locallyReadNotificationIdsProvider.notifier)
                .markRead(e.id);
            _repo.markRead(e.id);
            ref.invalidate(notificationsListProvider);
          },
        ),
      ),
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
      color: selected ? AppConfig.primaryColor : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: AppTextStyles.bodySmall(
              selected ? Colors.white : AppConfig.textColor,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isImportant,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  final NotificationItem item;
  final bool isImportant;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    if (isImportant) {
      return _ImportantNotificationCard(
        item: item,
        onTap: onTap,
        onDelete: onDelete,
        onMarkRead: onMarkRead,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey('notif_${item.id}'),
        background: _SwipeActionBackground(
          alignment: Alignment.centerLeft,
          color: AppConfig.primaryColor,
          icon: Icons.check,
          label: 'READ',
        ),
        secondaryBackground: const _SwipeActionBackground(
          alignment: Alignment.centerRight,
          color: AppConfig.errorRed,
          icon: Icons.delete_outline,
          label: 'DELETE',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onMarkRead();
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            onDelete();
            return true;
          }
          return false;
        },
        child: Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5EAF3)),
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeadingAvatar(item: item),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: item.read
                                    ? AppTextStyles.titleMedium(
                                        AppConfig.textColor,
                                      )
                                    : AppTextStyles.titleMedium(
                                        AppConfig.textColor,
                                      ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              item.timeAgo,
                              style: AppTextStyles.bodySmall(
                                const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium(
                            const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadingAvatar extends StatelessWidget {
  const _LeadingAvatar({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          item.imageUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final (icon, bg, fg) = switch (item.type) {
      NotificationFilterType.orders => (
        Icons.shopping_bag_outlined,
        const Color(0xFFDCEAFE),
        const Color(0xFF2563EB),
      ),
      NotificationFilterType.shipments => (
        Icons.local_shipping_outlined,
        const Color(0xFFDCFCE7),
        const Color(0xFF16A34A),
      ),
      NotificationFilterType.payments => (
        Icons.account_balance_wallet_outlined,
        const Color(0xFFEDE9FE),
        const Color(0xFF7C3AED),
      ),
      NotificationFilterType.promo => (
        Icons.local_offer_outlined,
        const Color(0xFFF3E8FF),
        const Color(0xFF9333EA),
      ),
      NotificationFilterType.all => (
        Icons.notifications_none,
        const Color(0xFFE2E8F0),
        const Color(0xFF475569),
      ),
    };

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: fg),
    );
  }
}

class _ImportantNotificationCard extends StatelessWidget {
  const _ImportantNotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey('notif_imp_${item.id}'),
        background: _SwipeActionBackground(
          alignment: Alignment.centerLeft,
          color: AppConfig.primaryColor,
          icon: Icons.check,
          label: 'READ',
        ),
        secondaryBackground: const _SwipeActionBackground(
          alignment: Alignment.centerRight,
          color: AppConfig.errorRed,
          icon: Icons.delete_outline,
          label: 'DELETE',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onMarkRead();
            return false;
          }
          if (direction == DismissDirection.endToStart) {
            onDelete();
            return true;
          }
          return false;
        },
        child: Material(
          color: const Color(0xFFFEF9E8),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF5D778)),
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE68A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFF8A6A00),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.titleMedium(
                            AppConfig.textColor,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: Text(
                      item.subtitle,
                      style: AppTextStyles.bodyMedium(const Color(0xFF8A6A00)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
