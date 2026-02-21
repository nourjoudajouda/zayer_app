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
}

enum NotificationFilterType {
  all,
  orders,
  shipments,
  promo,
}
