import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';

abstract class NotificationsRepository {
  Future<List<NotificationItem>> fetchNotifications();

  /// Best-effort. If backend endpoint isn't available yet, this should fail silently upstream.
  Future<void> markRead(String notificationId);

  /// Best-effort. If backend endpoint isn't available yet, this should fail silently upstream.
  Future<void> markAllRead();

  /// Best-effort delete. If backend endpoint isn't available yet, this should fail silently upstream.
  Future<void> delete(String notificationId);
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final res = await _dio.get<List<dynamic>>('/api/notifications');
    final list = res.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .where((n) => n.id.isNotEmpty)
        .toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    // Backend endpoints may vary. Try a small set, swallow errors.
    final candidates = <String>[
      '/api/notifications/$notificationId/read',
      '/api/notifications/$notificationId/mark-read',
      '/api/notifications/$notificationId',
    ];
    for (final path in candidates) {
      try {
        final res = await _dio.patch<dynamic>(
          path,
          data: path.endsWith(notificationId) ? {'read': true} : null,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) return;
      } catch (_) {
        // Try next
      }
    }
  }

  @override
  Future<void> markAllRead() async {
    final candidates = <String>[
      '/api/notifications/mark-all-read',
      '/api/notifications/read-all',
      '/api/notifications/mark_read_all',
    ];
    for (final path in candidates) {
      try {
        final res = await _dio.patch<dynamic>(
          path,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) return;
      } catch (_) {
        // Try next
      }
    }
  }

  @override
  Future<void> delete(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    final candidates = <String>[
      '/api/notifications/$notificationId',
      '/api/notifications/$notificationId/delete',
      '/api/notifications/$notificationId/remove',
    ];
    for (final path in candidates) {
      try {
        final res = await _dio.delete<dynamic>(
          path,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) return;
      } catch (_) {
        // Try next
      }
    }
  }
}

