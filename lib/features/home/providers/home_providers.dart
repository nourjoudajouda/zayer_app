import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Promo banner model. Replace with API/remote config later.
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
}

/// Mock home data. Replace with API later.
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
}

final homeUserGreetingProvider = Provider<String>((_) => 'Hazem');

/// Mock promo banners. Replace with API/remote config later.
final promoBannersProvider = Provider<List<PromoBanner>>((_) => [
  const PromoBanner(
    id: '1',
    label: 'FLASH SALE',
    title: 'Up to 40% off on US Premium Brands',
    ctaText: 'Shop Now',
  ),
  const PromoBanner(
    id: '2',
    label: 'NEW ARRIVALS',
    title: 'Latest products from Turkey & UAE',
    ctaText: 'Explore',
  ),
  const PromoBanner(
    id: '3',
    label: 'FREE SHIPPING',
    title: 'Orders over \$100 ship free',
    ctaText: 'Shop Now',
  ),
]);

/// Base list of markets (storeCount overwritten with real count from stores).
const List<MarketItem> _marketsBase = [
  MarketItem(id: 'usa', name: 'USA', imageUrl: null, storeCount: '0', countryCode: 'US'),
  MarketItem(id: 'turkey', name: 'Turkey', imageUrl: null, storeCount: '0', countryCode: 'TR'),
  MarketItem(id: 'uae', name: 'UAE', imageUrl: null, storeCount: '0', countryCode: 'AE'),
  MarketItem(id: 'uk', name: 'UK', imageUrl: null, storeCount: '0', countryCode: 'UK'),
];

final homeStoresProvider = Provider<List<StoreItem>>((_) => [
  const StoreItem(id: 'amazon', name: 'Amazon', category: 'GLOBAL SHOP', logoUrl: null, marketId: 'usa'),
  const StoreItem(id: 'zara', name: 'Zara', category: 'FASHION', logoUrl: null, marketId: 'turkey'),
  const StoreItem(id: 'nike', name: 'Nike', category: 'SPORTSWEAR', logoUrl: null, marketId: 'usa'),
  const StoreItem(id: 'sephora', name: 'Sephora', category: 'BEAUTY', logoUrl: null, marketId: 'usa'),
  const StoreItem(id: 'noon', name: 'Noon', category: 'MARKETPLACE', logoUrl: null, marketId: 'uae'),
  const StoreItem(id: 'asos', name: 'ASOS', category: 'FASHION', logoUrl: null, marketId: 'uk'),
]);

/// Markets with real store count: each market shows the number of stores linked to it.
final homeMarketsProvider = Provider<List<MarketItem>>((ref) {
  final stores = ref.watch(homeStoresProvider);
  return _marketsBase.map((m) {
    final count = stores.where((s) => s.marketId == m.id).length;
    return MarketItem(
      id: m.id,
      name: m.name,
      imageUrl: m.imageUrl,
      storeCount: count == 1 ? '1 store' : '$count stores',
      countryCode: m.countryCode,
    );
  }).toList();
});

final cartBadgeCountProvider = StateProvider<int>((_) => 2);
