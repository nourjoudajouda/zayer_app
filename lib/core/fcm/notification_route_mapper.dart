import 'package:zayer_app/core/fcm/notification_payload.dart';
import 'package:zayer_app/core/routing/app_router.dart';

/// Maps notification payloads to in-app routes.
/// Extensible for future target types (payment_success, order_processing,
/// tracking_assigned, shipment_delivered, support_reply, admin_broadcast).
NotificationNavigationTarget? mapPayloadToTarget(AppNotificationPayload payload) {
  if (!payload.hasTarget) return null;

  final type = payload.targetType?.toLowerCase();
  final id = payload.targetId;
  final routeKey = payload.routeKey?.toLowerCase();
  final meta = payload.meta;

  // Prefer route_key if it maps to a known route
  if (routeKey != null && routeKey.isNotEmpty) {
    final byKey = _routeFromRouteKey(routeKey, id);
    if (byKey != null) return byKey;
  }

  // Then target_type + target_id
  if (type != null && type.isNotEmpty) {
    final byType = _routeFromTargetType(type, id, meta);
    if (byType != null) return byType;
  }

  // Fallback: notifications list
  return NotificationNavigationTarget(
    route: AppRoutes.notifications,
    targetType: 'fallback',
  );
}

/// Known route_key values from backend.
NotificationNavigationTarget? _routeFromRouteKey(String routeKey, String? id) {
  switch (routeKey) {
    case 'order_detail':
    case 'order-detail':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: 'order',
          targetId: id,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.orders,
        targetType: 'orders_list',
      );
    case 'order_tracking':
    case 'order-tracking':
    case 'tracking':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderTracking}/$id',
          targetType: 'order',
          targetId: id,
        );
      }
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: 'orders_list');
    case 'order_invoice':
    case 'order-invoice':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderInvoice}/$id',
          targetType: 'order',
          targetId: id,
        );
      }
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: 'orders_list');
    case 'support_ticket':
    case 'support-ticket':
    case 'support_ticket_chat':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.supportTicket}/$id',
          targetType: 'support_ticket',
          targetId: id,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: 'support_inbox',
      );
    case 'wallet':
      return NotificationNavigationTarget(route: AppRoutes.wallet, targetType: 'wallet');
    case 'payment':
    case 'payment_status':
    case 'order_payment':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: 'order',
          targetId: id,
        );
      }
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: 'orders_list');
    case 'notifications':
    case 'notification_list':
      return NotificationNavigationTarget(
        route: AppRoutes.notifications,
        targetType: 'notifications',
      );
    case 'orders':
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: 'orders_list');
    case 'support_inbox':
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: 'support_inbox',
      );
    default:
      return null;
  }
}

NotificationNavigationTarget? _routeFromTargetType(
  String type,
  String? id,
  Map<String, dynamic>? meta,
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
          meta: meta,
        );
      }
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: type);
    case 'support_ticket':
    case 'support':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.supportTicket}/$id',
          targetType: type,
          targetId: id,
          meta: meta,
        );
      }
      return NotificationNavigationTarget(
        route: AppRoutes.supportInbox,
        targetType: type,
      );
    case 'wallet':
      return NotificationNavigationTarget(route: AppRoutes.wallet, targetType: type);
    case 'payment':
    case 'shipment':
      if (id != null && id.isNotEmpty) {
        return NotificationNavigationTarget(
          route: '${AppRoutes.orderDetail}/$id',
          targetType: type,
          targetId: id,
          meta: meta,
        );
      }
      return NotificationNavigationTarget(route: AppRoutes.orders, targetType: type);
    case 'notification':
    case 'notifications':
      return NotificationNavigationTarget(
        route: AppRoutes.notifications,
        targetType: type,
      );
    default:
      return null;
  }
}
