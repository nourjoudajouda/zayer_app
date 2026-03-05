import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_prefs_model.dart';

/// Fetch from API: GET /api/me/notification-preferences
Future<NotificationPrefsModel> _fetchPrefs() async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/me/notification-preferences');
    final d = res.data;
    if (d != null) {
      return NotificationPrefsModel(
        pushEnabled: d['push_enabled'] != false,
        emailEnabled: d['email_enabled'] != false,
        smsEnabled: d['sms_enabled'] == true,
        liveStatusUpdates: d['live_status_updates'] != false,
        quietHoursEnabled: d['quiet_hours_enabled'] != false,
        quietHoursFrom: d['quiet_hours_from'] as String? ?? '22:00',
        quietHoursTo: d['quiet_hours_to'] as String? ?? '07:00',
      );
    }
  } catch (_) {}
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

  void setSms(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(smsEnabled: value);
  }

  void setLiveStatusUpdates(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(liveStatusUpdates: value);
  }

  void setSmartFilter(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(smartFilter: value);
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

  void setDutyTaxPayments(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(dutyTaxPayments: value);
  }

  void setDocumentRequests(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(documentRequests: value);
  }

  void setPaymentFailed(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(paymentFailed: value);
  }

  void setPaymentReminders(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(paymentReminders: value);
  }

  void setPromotions(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(promotions: value);
  }

  void setMuteAllMarketing(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(muteAllMarketing: value);
  }

  void setQuietHoursEnabled(bool value) {
    state = (state ?? const NotificationPrefsModel()).copyWith(quietHoursEnabled: value);
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
