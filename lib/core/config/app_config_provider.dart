import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'app_config_repository.dart';
import 'models/app_bootstrap_config.dart';

final _repository = AppConfigRepositoryImpl();

/// In-memory cache. Cleared on refresh so next read fetches again.
AppBootstrapConfig? _cachedConfig;

/// Provides [AppBootstrapConfig] with loading/error states.
/// Cached in memory until [bootstrapConfigRefreshProvider] is called.
/// When config has [api_base_url] from admin, updates [ApiClient] and persists.
final bootstrapConfigProvider =
    FutureProvider<AppBootstrapConfig>((ref) async {
  if (_cachedConfig != null) return _cachedConfig!;
  final config = await _repository.fetchBootstrapConfig();
  _cachedConfig = config;
  if (config.apiBaseUrl != null && config.apiBaseUrl!.trim().isNotEmpty) {
    await ApiClient.setBaseUrlFromAdmin(config.apiBaseUrl!);
  }
  return config;
});

/// Call to clear cache and refetch. Use in Retry or pull-to-refresh.
/// Accepts [ref] from ConsumerState/Consumer (WidgetRef or Ref).
void bootstrapConfigRefresh(dynamic ref) {
  _cachedConfig = null;
  ref.invalidate(bootstrapConfigProvider);
}

/// True when admin enables development mode in bootstrap (development_mode: true).
final developmentModeProvider = Provider<bool>((ref) {
  final config = ref.watch(bootstrapConfigProvider).valueOrNull;
  return config?.developmentMode ?? false;
});

/// App display name from backend bootstrap. Falls back to "Eshterely".
final appDisplayNameProvider = Provider<String>((ref) {
  final cfg = ref.watch(bootstrapConfigProvider).valueOrNull;
  final name = cfg?.appName?.trim();
  return (name != null && name.isNotEmpty) ? name : 'Eshterely';
});
