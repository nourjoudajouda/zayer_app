import 'package:flutter_test/flutter_test.dart';
import 'package:zayer_app/core/fcm/notification_payload.dart';
import 'package:zayer_app/core/fcm/notification_route_mapper.dart';
import 'package:zayer_app/core/routing/app_router.dart';

void main() {
  group('AppNotificationPayload', () {
    test('parses target_type and target_id', () {
      final p = AppNotificationPayload.fromMap({
        'target_type': 'order',
        'target_id': '123',
      });
      expect(p.targetType, 'order');
      expect(p.targetId, '123');
      expect(p.hasTarget, true);
    });

    test('parses route_key', () {
      final p = AppNotificationPayload.fromMap({
        'route_key': 'order_detail',
        'target_id': '456',
      });
      expect(p.routeKey, 'order_detail');
      expect(p.targetId, '456');
      expect(p.hasTarget, true);
    });

    test('hasTarget false when empty', () {
      expect(AppNotificationPayload.fromMap({}).hasTarget, false);
      expect(
        AppNotificationPayload.fromMap({'target_type': '', 'target_id': ''})
            .hasTarget,
        false,
      );
    });

    test('parses meta from meta or payload', () {
      final p = AppNotificationPayload.fromMap({
        'target_type': 'order',
        'meta': {'screen': 'tracking'},
      });
      expect(p.meta, {'screen': 'tracking'});
    });
  });

  group('mapPayloadToTarget', () {
    test('order_detail route_key with id', () {
      final p = AppNotificationPayload.fromMap({
        'route_key': 'order_detail',
        'target_id': '99',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, '${AppRoutes.orderDetail}/99');
      expect(t.targetType, 'order');
      expect(t.targetId, '99');
    });

    test('order_tracking route_key with id', () {
      final p = AppNotificationPayload.fromMap({
        'route_key': 'order_tracking',
        'target_id': '42',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, '${AppRoutes.orderTracking}/42');
    });

    test('support_ticket with id', () {
      final p = AppNotificationPayload.fromMap({
        'target_type': 'support_ticket',
        'target_id': 'TKT-1',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, '${AppRoutes.supportTicket}/TKT-1');
    });

    test('wallet', () {
      final p = AppNotificationPayload.fromMap({
        'target_type': 'wallet',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, AppRoutes.wallet);
    });

    test('missing target_type and route_key returns null', () {
      final p = AppNotificationPayload.fromMap({'target_id': '1'});
      expect(mapPayloadToTarget(p), isNull);
    });

    test('empty payload returns null', () {
      final p = AppNotificationPayload.fromMap({});
      expect(mapPayloadToTarget(p), isNull);
    });

    test('unknown route_key falls back to notifications', () {
      final p = AppNotificationPayload.fromMap({
        'route_key': 'unknown_key',
        'target_id': 'x',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, AppRoutes.notifications);
      expect(t.targetType, 'fallback');
    });

    test('order with meta screen tracking', () {
      final p = AppNotificationPayload.fromMap({
        'target_type': 'order',
        'target_id': '7',
        'meta': {'screen': 'tracking'},
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, '${AppRoutes.orderTracking}/7');
    });

    test('order_detail without id goes to orders list', () {
      final p = AppNotificationPayload.fromMap({
        'route_key': 'order_detail',
      });
      final t = mapPayloadToTarget(p);
      expect(t, isNotNull);
      expect(t!.route, AppRoutes.orders);
    });
  });
}
