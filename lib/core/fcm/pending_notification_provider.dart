import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_payload.dart';

/// Holds a notification tap target to be applied when the app is ready (e.g. after splash).
/// Used for background and terminated launch navigation.
final pendingNotificationTargetProvider =
    NotifierProvider<PendingNotificationNotifier, NotificationNavigationTarget?>(
  PendingNotificationNotifier.new,
);

class PendingNotificationNotifier extends Notifier<NotificationNavigationTarget?> {
  @override
  NotificationNavigationTarget? build() => null;

  void setTarget(NotificationNavigationTarget target) {
    state = target;
  }

  void clear() {
    state = null;
  }
}
