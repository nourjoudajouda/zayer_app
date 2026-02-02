/// Notification preferences model. API: GET/PATCH /api/me/notification-preferences later.
class NotificationPrefsModel {
  const NotificationPrefsModel({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.orderUpdates = true,
    this.shipmentUpdates = true,
    this.customsCompliance = true,
    this.paymentReminders = true,
    this.promotions = false,
    this.quietHoursFrom = '22:00',
    this.quietHoursTo = '07:00',
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool orderUpdates;
  final bool shipmentUpdates;
  final bool customsCompliance;
  final bool paymentReminders;
  final bool promotions;
  final String quietHoursFrom;
  final String quietHoursTo;

  NotificationPrefsModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? orderUpdates,
    bool? shipmentUpdates,
    bool? customsCompliance,
    bool? paymentReminders,
    bool? promotions,
    String? quietHoursFrom,
    String? quietHoursTo,
  }) {
    return NotificationPrefsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      shipmentUpdates: shipmentUpdates ?? this.shipmentUpdates,
      customsCompliance: customsCompliance ?? this.customsCompliance,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      promotions: promotions ?? this.promotions,
      quietHoursFrom: quietHoursFrom ?? this.quietHoursFrom,
      quietHoursTo: quietHoursTo ?? this.quietHoursTo,
    );
  }
}
