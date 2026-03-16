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
    if (locallyReadIds.isEmpty) return list;
    return [
      for (final n in list)
        n.copyWith(read: n.read || locallyReadIds.contains(n.id)),
    ];
  } catch (_) {}
  return [];
});
