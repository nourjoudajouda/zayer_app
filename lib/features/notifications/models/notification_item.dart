/// Single notification for list/grouping. API: GET /api/notifications.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.read = false,
    this.important = false,
    this.actionLabel,
    this.actionRoute,
    this.imageUrl,
  });

  final String id;
  final NotificationFilterType type;

  /// Original category/type string from backend (future-ready).
  final String category;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool read;
  final bool important;
  final String? actionLabel;
  final String? actionRoute;
  final String? imageUrl;

  NotificationItem copyWith({
    String? id,
    NotificationFilterType? type,
    String? category,
    String? title,
    String? subtitle,
    String? timeAgo,
    bool? read,
    bool? important,
    String? actionLabel,
    String? actionRoute,
    String? imageUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timeAgo: timeAgo ?? this.timeAgo,
      read: read ?? this.read,
      important: important ?? this.important,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// From API: type (orders|shipments|promo), title, subtitle, time_ago, read, important, action_label, action_route
  static NotificationItem fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'orders';
    final normalized = typeStr.toLowerCase();
    final type = switch (normalized) {
      'all' || 'general' || 'notification' => NotificationFilterType.all,
      'payments' ||
      'payment' ||
      'payment_update' ||
      'wallet' ||
      'wallet_update' => NotificationFilterType.payments,
      'orders' || 'order' || 'order_update' => NotificationFilterType.orders,
      'shipments' ||
      'shipment' ||
      'shipment_update' ||
      'tracking_update' => NotificationFilterType.shipments,
      'promo' || 'promotion' => NotificationFilterType.promo,
      _ =>
        normalized.contains('ship') || normalized.contains('track')
            ? NotificationFilterType.shipments
            : (normalized.contains('pay') || normalized.contains('wallet'))
            ? NotificationFilterType.payments
            : (normalized.contains('promo') || normalized.contains('offer')
                  ? NotificationFilterType.promo
                  : NotificationFilterType.orders),
    };
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: type,
      category: typeStr,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? '',
      read: json['read'] == true,
      important: json['important'] == true,
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

enum NotificationFilterType { all, orders, shipments, payments, promo }
