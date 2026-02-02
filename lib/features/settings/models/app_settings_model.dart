/// Settings & Preferences model. API will replace mock; see settings_providers.
class AppSettingsModel {
  const AppSettingsModel({
    this.languageCode = 'en',
    this.languageLabel = 'English (US)',
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.defaultWarehouseId = 'delaware_us',
    this.defaultWarehouseLabel = 'Delaware, US',
    this.smartConsolidationEnabled = true,
    this.autoInsuranceEnabled = false,
    this.notificationCenterSummary = 'Push & Email active • 2 muted',
    this.serverRegion = 'Region-West-1',
  });

  final String languageCode;
  final String languageLabel;
  final String currencyCode;
  final String currencySymbol;
  final String defaultWarehouseId;
  final String defaultWarehouseLabel;
  final bool smartConsolidationEnabled;
  final bool autoInsuranceEnabled;
  final String notificationCenterSummary;
  final String serverRegion;

  AppSettingsModel copyWith({
    String? languageCode,
    String? languageLabel,
    String? currencyCode,
    String? currencySymbol,
    String? defaultWarehouseId,
    String? defaultWarehouseLabel,
    bool? smartConsolidationEnabled,
    bool? autoInsuranceEnabled,
    String? notificationCenterSummary,
    String? serverRegion,
  }) {
    return AppSettingsModel(
      languageCode: languageCode ?? this.languageCode,
      languageLabel: languageLabel ?? this.languageLabel,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      defaultWarehouseLabel: defaultWarehouseLabel ?? this.defaultWarehouseLabel,
      smartConsolidationEnabled:
          smartConsolidationEnabled ?? this.smartConsolidationEnabled,
      autoInsuranceEnabled: autoInsuranceEnabled ?? this.autoInsuranceEnabled,
      notificationCenterSummary:
          notificationCenterSummary ?? this.notificationCenterSummary,
      serverRegion: serverRegion ?? this.serverRegion,
    );
  }
}
