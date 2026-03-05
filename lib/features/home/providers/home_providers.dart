import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/config/models/app_bootstrap_config.dart';

/// Promo banner model. From bootstrap API.
class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.label,
    required this.title,
    required this.ctaText,
    this.imageUrl,
    this.deepLink,
  });
  final String id;
  final String label;
  final String title;
  final String ctaText;
  final String? imageUrl;
  final String? deepLink;

  static PromoBanner fromConfig(PromoBannerConfig c) => PromoBanner(
        id: c.id.toString(),
        label: c.label,
        title: c.title,
        ctaText: c.ctaText,
        imageUrl: c.imageUrl.isEmpty ? null : c.imageUrl,
        deepLink: c.deepLink.isEmpty ? null : c.deepLink,
      );
}

/// Market item. From bootstrap API.
class MarketItem {
  const MarketItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.storeCount,
    this.countryCode,
  });
  final String id;
  final String name;
  final String? imageUrl;
  /// Display string e.g. "250+ stores" or "12 stores" (real count when from API).
  final String storeCount;
  /// ISO country code for Markets filter (e.g. US, TR).
  final String? countryCode;
}

class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.marketId,
  });
  final String id;
  final String name;
  final String category;
  final String? logoUrl;
  /// Market id this store belongs to (e.g. 'usa', 'turkey') for real store count.
  final String? marketId;

  static StoreItem fromConfig(StoreConfig c) => StoreItem(
        id: c.id,
        name: c.name,
        category: c.description.isNotEmpty ? c.description : 'STORE',
        logoUrl: c.logoUrl.isEmpty ? null : c.logoUrl,
        marketId: c.countryCode.isEmpty ? null : c.countryCode.toLowerCase(),
      );
}

final homeUserGreetingProvider = Provider<String>((_) => 'Hey');

/// Promo banners from bootstrap API.
final promoBannersProvider = Provider<List<PromoBanner>>((ref) {
  final config = ref.watch(bootstrapConfigProvider).valueOrNull;
  if (config?.promoBanners == null || config!.promoBanners.isEmpty) {
    return [];
  }
  return config.promoBanners.map(PromoBanner.fromConfig).toList();
});

/// Markets from bootstrap API (countries with store count from featured_stores).
final homeMarketsProvider = Provider<List<MarketItem>>((ref) {
  final config = ref.watch(bootstrapConfigProvider).valueOrNull;
  final markets = config?.markets;
  if (markets == null) return [];
  final stores = markets.featuredStores;
  return markets.countries
      .where((c) => c.code != 'ALL')
      .map((c) {
        final count = stores.where((s) => s.countryCode == c.code).length;
        return MarketItem(
          id: c.code.toLowerCase(),
          name: c.name,
          imageUrl: null,
          storeCount: count == 1 ? '1 store' : '$count stores',
          countryCode: c.code,
        );
      })
      .toList();
});

/// Featured stores from bootstrap API.
final homeStoresProvider = Provider<List<StoreItem>>((ref) {
  final config = ref.watch(bootstrapConfigProvider).valueOrNull;
  final stores = config?.markets?.featuredStores;
  if (stores == null || stores.isEmpty) return [];
  return stores.map(StoreItem.fromConfig).toList();
});

final cartBadgeCountProvider = StateProvider<int>((_) => 0);
