import 'package:zayer_app/core/fcm/notification_payload.dart';
import 'package:zayer_app/core/routing/app_router.dart';

/// Maps notification payloads to in-app routes.
/// Extensible for future target types (payment_success, order_processing,
/// tracking_assigned, shipment_delivered, support_reply, admin_broadcast).
NotificationNavigationTarget? mapPayloadToTarget(AppNotificationPayload payload) {
  final type = payload.targetType?.toLowerCase();
  final id = payload.targetId;
  final routeKey = payload.routeKey?.toLowerCase();
  final actionRoute = payload.actionRoute?.trim();
  final meta = payload.meta;
  final notificationId = payload.notificationId;

  // 1) Prefer route_key if it maps to a known route
  if (routeKey != null && routeKey.isNotEmpty) {
    final byKey = _routeFromRouteKey(routeKey, id, notificationId);
    if (byKey != null) return byKey;
  }

  // 2) Then target_type + target_id
  if (type != null && type.isNotEmpty) {
    final byType = _routeFromTargetType(type, id, meta, notificationId);
    if (byType != null) return byType;
  }

  // 3) Admin-defined action_route (safe path only: starts with /, no protocol)
  if (actionRoute != null &&
      actionRoute.isNotEmpty &&
      actionRoute.startsWith('/') &&
      !actionRoute.contains('://') &&
      !actionRoute.contains('..')) {
    final targetType = type ?? 'action';
    return NotificationNavigationTarget(
      route: actionRoute,
      targetType: targetType,
      targetId: id,
      notificationId: notificationId,
      meta: meta,
    );
  }

  // 4) No target info: fallback to notifications list
  if (!payload.hasTarget) return null;

  return NotificationNavigationTarget(
    route: AppRoutes.notifications,
    targetType: 'fallback',
    notificationId: notificationId,
  );
}

/// Known route_key values from backend.
NotificationNavigationTarget? _routeFromRouteKey(
  String routeKey,
  String? id,
  String? notificationId,
) {
  switch (routeKey) {
    case 'order_detail':
    case 'order-detail':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: 'order',
          targetId: id,
          notificationId: notificationId,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
        notificationId: notificationId,
      );
    case 'order_tracking':
    case 'order-tracking':
    case 'tracking':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderTracking}/$id',
          targetType: 'order',
          targetId: id,
          notificationId: notificationId,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
        notificationId: notificationId,
      );
    case 'order_invoice':
    case 'order-invoice':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderInvoice}/$id',
          targetType: 'order',
          targetId: id,
          notificationId: notificationId,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
        notificationId: notificationId,
      );
    case 'support_ticket':
    case 'support-ticket':
    case 'support_ticket_chat':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.supportTicket}/$id',
          targetType: 'support_ticket',
          targetId: id,
          notificationId: notificationId,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: 'support_inbox',
        notificationId: notificationId,
      );
    case 'wallet':
      return NotificationNavigationTarget(
        route: AppRoutes.wallet,
        targetType: 'wallet',
        notificationId: notificationId,
      );
    case 'payment':
    case 'payment_status':
    case 'order_payment':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: 'order',
          targetId: id,
          notificationId: notificationId,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
        notificationId: notificationId,
      );
    case 'notifications':
    case 'notification_list':
      return NotificationNavigationTarget(
        route: AppRoutes.notifications,
        targetType: 'notifications',
        notificationId: notificationId,
      );
    case 'orders':
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
        notificationId: notificationId,
      );
    case 'support_inbox':
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: 'support_inbox',
        notificationId: notificationId,
      );
    default:
      return null;
  }
}

NotificationNavigationTarget? _routeFromTargetType(
  String type,
  String? id,
  Map<String, dynamic>? meta,
  String? notificationId,
) {
  switch (type) {
    case 'order':
      if (id != null && id.isNotEmpty) {
        // Optional: meta could request tracking vs detail
        final preferTracking = meta?['screen'] == 'tracking';
        final path = preferTracking
            ? '${AppRoutes.orderTracking}/$id'
            : '${AppRoutes.orderDetail}/$id';
        return NotificationNavigationTarget(
          route: path,
          targetType: type,
          targetId: id,
          notificationId: notificationId,
          meta: meta,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: type,
        notificationId: notificationId,
      );
    case 'support_ticket':
    case 'support':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.supportTicket}/$id',
          targetType: type,
          targetId: id,
          notificationId: notificationId,
          meta: meta,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: type,
        notificationId: notificationId,
      );
    case 'wallet':
      return NotificationNavigationTarget(
        route: AppRoutes.wallet,
        targetType: type,
        notificationId: notificationId,
      );
    case 'payment':
    case 'shipment':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: type,
          targetId: id,
          notificationId: notificationId,
          meta: meta,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: type,
        notificationId: notificationId,
      );
    case 'notification':
    case 'notifications':
      return NotificationNavigationTarget(
        route: AppRoutes.notifications,
        targetType: type,
        notificationId: notificationId,
      );
    default:
      return null;
  }
}
