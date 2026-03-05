/// Single notification for list/grouping. API: GET /api/notifications.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.read = false,
    this.important = false,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final NotificationFilterType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool read;
  final bool important;
  final String? actionLabel;
  final String? actionRoute;

  /// From API: type (orders|shipments|promo), title, subtitle, time_ago, read, important, action_label, action_route
  static NotificationItem fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'orders';
    final type = switch (typeStr.toLowerCase()) {
      'orders' => NotificationFilterType.orders,
      'shipments' => NotificationFilterType.shipments,
      'promo' => NotificationFilterType.promo,
      _ => NotificationFilterType.orders,
    };
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? '',
      read: json['read'] == true,
      important: json['important'] == true,
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
    );
  }
}

enum NotificationFilterType {
  all,
  orders,
  shipments,
  promo,
}
