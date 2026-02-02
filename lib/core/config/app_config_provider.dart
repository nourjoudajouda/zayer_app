import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config_repository.dart';
import 'models/app_bootstrap_config.dart';

final _repository = AppConfigRepositoryMock();

/// In-memory cache. Cleared on refresh so next read fetches again.
AppBootstrapConfig? _cachedConfig;

/// Provides [AppBootstrapConfig] with loading/error states.
/// Cached in memory until [bootstrapConfigRefreshProvider] is called.
final bootstrapConfigProvider =
    FutureProvider<AppBootstrapConfig>((ref) async {
  if (_cachedConfig != null) return _cachedConfig!;
  final config = await _repository.fetchBootstrapConfig();
  _cachedConfig = config;
  return config;
});

/// Call to clear cache and refetch. Use in Retry or pull-to-refresh.
/// Accepts [ref] from ConsumerState/Consumer (WidgetRef or Ref).
void bootstrapConfigRefresh(dynamic ref) {
  _cachedConfig = null;
  ref.invalidate(bootstrapConfigProvider);
}
