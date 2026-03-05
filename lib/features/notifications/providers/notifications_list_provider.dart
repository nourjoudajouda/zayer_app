import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';

/// Notifications from API: GET /api/notifications
/// Response: [{ id, type, title, subtitle, time_ago, read, important, action_label, action_route }, ...]
final notificationsListProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/notifications');
    final list = res.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .where((n) => n.id.isNotEmpty)
        .toList();
  } catch (_) {}
  return [];
});
