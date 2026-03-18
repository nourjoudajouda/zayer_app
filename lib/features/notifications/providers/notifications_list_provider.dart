import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../repositories/notifications_repository.dart';
import 'notifications_state_provider.dart';

/// Notifications from API: GET /api/notifications
/// Response: [{ id, type, title, subtitle, time_ago, read, important, action_label, action_route }, ...]
final notificationsListProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  try {
    final repo = NotificationsRepositoryImpl();
    final list = await repo.fetchNotifications();
    final locallyReadIds = ref.watch(locallyReadNotificationIdsProvider);
    final locallyDeletedIds = ref.watch(locallyDeletedNotificationIdsProvider);
    final filtered = locallyDeletedIds.isEmpty
        ? list
        : list.where((n) => !locallyDeletedIds.contains(n.id)).toList();
    if (locallyReadIds.isEmpty) return filtered;
    return [
      for (final n in filtered)
        n.copyWith(read: n.read || locallyReadIds.contains(n.id)),
    ];
  } catch (_) {}
  return [];
});
