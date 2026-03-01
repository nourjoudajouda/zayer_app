/// Notification preferences model. API: GET/PATCH /api/me/notification-preferences later.
class NotificationPrefsModel {
  const NotificationPrefsModel({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.liveStatusUpdates = true,
    this.smartFilter = true,
    this.dutyTaxPayments = true,
    this.documentRequests = true,
    this.paymentFailed = true,
    this.muteAllMarketing = false,
    this.quietHoursEnabled = true,
    this.quietHoursFrom = '22:00',
    this.quietHoursTo = '07:00',
    // Legacy aliases
    this.orderUpdates = true,
    this.shipmentUpdates = true,
    this.customsCompliance = true,
    this.paymentReminders = true,
    this.promotions = false,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool liveStatusUpdates;
  final bool smartFilter;
  final bool dutyTaxPayments;
  final bool documentRequests;
  final bool paymentFailed;
  final bool muteAllMarketing;
  final bool quietHoursEnabled;
  final String quietHoursFrom;
  final String quietHoursTo;
  final bool orderUpdates;
  final bool shipmentUpdates;
  final bool customsCompliance;
  final bool paymentReminders;
  final bool promotions;

  NotificationPrefsModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? liveStatusUpdates,
    bool? smartFilter,
    bool? dutyTaxPayments,
    bool? documentRequests,
    bool? paymentFailed,
    bool? muteAllMarketing,
    bool? quietHoursEnabled,
    String? quietHoursFrom,
    String? quietHoursTo,
    bool? orderUpdates,
    bool? shipmentUpdates,
    bool? customsCompliance,
    bool? paymentReminders,
    bool? promotions,
  }) {
    return NotificationPrefsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      liveStatusUpdates: liveStatusUpdates ?? this.liveStatusUpdates,
      smartFilter: smartFilter ?? this.smartFilter,
      dutyTaxPayments: dutyTaxPayments ?? this.dutyTaxPayments,
      documentRequests: documentRequests ?? this.documentRequests,
      paymentFailed: paymentFailed ?? this.paymentFailed,
      muteAllMarketing: muteAllMarketing ?? this.muteAllMarketing,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursFrom: quietHoursFrom ?? this.quietHoursFrom,
      quietHoursTo: quietHoursTo ?? this.quietHoursTo,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      shipmentUpdates: shipmentUpdates ?? this.shipmentUpdates,
      customsCompliance: customsCompliance ?? this.customsCompliance,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      promotions: promotions ?? this.promotions,
    );
  }
}
