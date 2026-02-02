import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_prefs_model.dart';

/// Mock fetch. Replace with GET /api/me/notification-preferences later.
Future<NotificationPrefsModel> _fetchPrefs() async {
  await Future.delayed(const Duration(milliseconds: 200));
  return const NotificationPrefsModel();
}

final notificationPrefsProvider =
    FutureProvider<NotificationPrefsModel>((ref) => _fetchPrefs());

/// Editable prefs in UI. Save triggers API later.
final notificationPrefsNotifierProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefsModel?>(
        (ref) {
  return NotificationPrefsNotifier();
});

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefsModel?> {
  NotificationPrefsNotifier() : super(null);

  void updateFrom(NotificationPrefsModel base) {
    state ??= base;
  }

  void setPush(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(pushEnabled: value);
  }

  void setEmail(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(emailEnabled: value);
  }

  void setOrderUpdates(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(orderUpdates: value);
  }

  void setShipmentUpdates(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(shipmentUpdates: value);
  }

  void setCustomsCompliance(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(customsCompliance: value);
  }

  void setPaymentReminders(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(paymentReminders: value);
  }

  void setPromotions(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(promotions: value);
  }

  void setQuietHours(String from, String to) {
    state = (state ?? const NotificationPrefsModel()).copyWith(
      quietHoursFrom: from,
      quietHoursTo: to,
    );
  }

  void clear() {
    state = null;
  }
}
