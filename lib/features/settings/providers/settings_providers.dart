import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/app_settings_model.dart';

/// Warehouse option for default warehouse selection.
class WarehouseOption {
  const WarehouseOption({required this.id, required this.label});
  final String id;
  final String label;
}

/// Warehouses from API: GET /api/warehouses
/// Response: [{"id": "delaware_us", "label": "Delaware, US"}, ...]
final warehousesProvider = FutureProvider<List<WarehouseOption>>((ref) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/warehouses');
    final list = res.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => WarehouseOption(
              id: e['id'] as String? ?? '',
              label: e['label'] as String? ?? '',
            ))
        .where((w) => w.id.isNotEmpty)
        .toList();
  } catch (_) {}
  return [];
});

/// Settings from API: GET /api/me/settings
Future<AppSettingsModel> _fetchSettings() async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/me/settings');
    final d = res.data;
    if (d != null) {
      return AppSettingsModel(
        languageCode: d['language_code'] as String? ?? 'en',
        languageLabel: d['language_label'] as String? ?? 'English (US)',
        currencyCode: d['currency_code'] as String? ?? 'USD',
        currencySymbol: d['currency_symbol'] as String? ?? r'$',
        defaultWarehouseId: d['default_warehouse_id'] as String? ?? 'delaware_us',
        defaultWarehouseLabel: d['default_warehouse_label'] as String? ?? 'Delaware, US',
        smartConsolidationEnabled: d['smart_consolidation_enabled'] != false,
        autoInsuranceEnabled: d['auto_insurance_enabled'] == true,
      );
    }
  } catch (_) {}
  return const AppSettingsModel();
}

/// Settings data from API.
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
