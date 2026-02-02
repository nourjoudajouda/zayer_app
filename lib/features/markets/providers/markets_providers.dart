import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/config/models/app_bootstrap_config.dart';

/// Selected country filter. null = ALL.
final selectedCountryCodeProvider = StateProvider<String?>((_) => null);

/// Markets config from bootstrap. Safe fallback.
final marketsConfigProvider = Provider<MarketsConfig>((ref) {
  final configAsync = ref.watch(bootstrapConfigProvider);
  return configAsync.whenOrNull(
        data: (c) => c.markets,
      ) ??
      MarketsConfig.fallback;
});

/// Filtered stores by selected country.
final filteredStoresProvider = Provider<List<StoreConfig>>((ref) {
  final config = ref.watch(marketsConfigProvider);
  final country = ref.watch(selectedCountryCodeProvider);

  if (country == null || country == 'ALL') {
    return config.featuredStores;
  }
  return config.featuredStores
      .where((s) => s.countryCode.toUpperCase() == country.toUpperCase())
      .toList();
});
