import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings_model.dart';

/// Mock settings repository. Replace with API (GET/PATCH /api/me/settings) later.
Future<AppSettingsModel> _fetchSettings() async {
  await Future.delayed(const Duration(milliseconds: 300));
  return const AppSettingsModel();
}

/// Settings data. API will plug in here.
final settingsProvider =
    FutureProvider<AppSettingsModel>((ref) => _fetchSettings());

/// Local overrides for toggles/selection (e.g. user toggled Smart Consolidation).
/// Persist to API when backend is ready.
final settingsOverridesProvider =
    StateNotifierProvider<SettingsOverridesNotifier, AppSettingsModel?>((ref) {
  return SettingsOverridesNotifier();
});

class SettingsOverridesNotifier extends StateNotifier<AppSettingsModel?> {
  SettingsOverridesNotifier() : super(null);

  void setSmartConsolidation(bool value) {
    state = (state ?? const AppSettingsModel()).copyWith(
      smartConsolidationEnabled: value,
    );
  }

  void setAutoInsurance(bool value) {
    state = (state ?? const AppSettingsModel()).copyWith(
      autoInsuranceEnabled: value,
    );
  }

  void setCurrency(String code, String symbol) {
    state = (state ?? const AppSettingsModel()).copyWith(
      currencyCode: code,
      currencySymbol: symbol,
    );
  }

  void setWarehouse(String id, String label) {
    state = (state ?? const AppSettingsModel()).copyWith(
      defaultWarehouseId: id,
      defaultWarehouseLabel: label,
    );
  }

  void setLanguage(String code, String label) {
    state = (state ?? const AppSettingsModel()).copyWith(
      languageCode: code,
      languageLabel: label,
    );
  }

  void clear() {
    state = null;
  }
}

/// Combined settings: base from provider + overrides.
final effectiveSettingsProvider = Provider<AppSettingsModel>((ref) {
  final async = ref.watch(settingsProvider);
  final overrides = ref.watch(settingsOverridesProvider);
  return async.when(
    data: (base) => overrides ?? base,
    loading: () => overrides ?? const AppSettingsModel(),
    error: (_, st) => overrides ?? const AppSettingsModel(),
  );
});
