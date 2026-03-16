/// Normalized target for notification-driven navigation.
/// Built from backend payload fields: target_type, target_id, route_key, meta.
class NotificationNavigationTarget {
  const NotificationNavigationTarget({
    required this.route,
    required this.targetType,
    this.targetId,
    this.notificationId,
    this.meta,
  });

  /// GoRouter path (e.g. /order-detail/123, /wallet).
  final String route;

  /// Backend target_type (order, support_ticket, wallet, etc.).
  final String targetType;

  /// Backend target_id when applicable.
  final String? targetId;

  /// Backend notification identifier (if provided) for read-state sync.
  final String? notificationId;

  /// Optional extra payload for the screen.
  final Map<String, dynamic>? meta;

  @override
  String toString() =>
      'NotificationNavigationTarget(route: $route, targetType: $targetType, targetId: $targetId, notificationId: $notificationId)';
}

/// Raw FCM/data payload from backend.
/// Supports target_type, target_id, route_key, action_label, action_route, and meta/payload.
class AppNotificationPayload {
  AppNotificationPayload.fromMap(Map<String, dynamic> map)
      : targetType = _string(map['target_type']),
        targetId = _string(map['target_id']),
        routeKey = _string(map['route_key']),
        actionLabel = _string(map['action_label']),
        actionRoute = _string(map['action_route']),
        notificationId = _string(map['notification_id'] ?? map['notificationId'] ?? map['id']),
        meta = _safeMap(map['meta']) ?? _safeMap(map['payload']);

  final String? targetType;
  final String? targetId;
  final String? routeKey;
  /// Optional label for the notification action (e.g. "View order").
  final String? actionLabel;
  /// Optional explicit route path from admin (e.g. "/order-detail/123").
  final String? actionRoute;
  final String? notificationId;
  final Map<String, dynamic>? meta;

  static String? _string(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic>? _safeMap(dynamic v) {
    if (v == null) return null;
    try {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
    } catch (_) {}
    return null;
  }

  bool get hasTarget =>
      (targetType != null && targetType!.isNotEmpty) ||
      (routeKey != null && routeKey!.isNotEmpty) ||
      (actionRoute != null && actionRoute!.isNotEmpty);
}
