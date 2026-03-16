import 'package:flutter_test/flutter_test.dart';
import 'package:zayer_app/core/routing/app_router.dart';
import 'package:zayer_app/features/notifications/utils/notification_action_route_resolver.dart';

void main() {
  group('resolveNotificationActionRoute', () {
    test('returns null for empty', () {
      expect(resolveNotificationActionRoute(null), isNull);
      expect(resolveNotificationActionRoute(''), isNull);
      expect(resolveNotificationActionRoute('   '), isNull);
    });

    test('passes through absolute app routes', () {
      expect(resolveNotificationActionRoute('/wallet'), '/wallet');
    });

    test('maps route_key:id format', () {
      expect(
        resolveNotificationActionRoute('order_detail:123'),
        '${AppRoutes.orderDetail}/123',
      );
      expect(
        resolveNotificationActionRoute('support_ticket|T1'),
        '${AppRoutes.supportTicket}/T1',
      );
    });

    test('maps route_key without id to safe fallback', () {
      expect(
        resolveNotificationActionRoute('notifications'),
        AppRoutes.notifications,
      );
    });
  });
}

