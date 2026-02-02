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
  });
  final String id;
  final String name;
  final String category;
  final String? logoUrl;
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

final homeMarketsProvider = Provider<List<MarketItem>>((_) => [
  const MarketItem(id: 'usa', name: 'USA', imageUrl: null, storeCount: '250+ stores', countryCode: 'US'),
  const MarketItem(id: 'turkey', name: 'Turkey', imageUrl: null, storeCount: '180+ stores', countryCode: 'TR'),
  const MarketItem(id: 'uae', name: 'UAE', imageUrl: null, storeCount: '120+ stores', countryCode: 'AE'),
  const MarketItem(id: 'uk', name: 'UK', imageUrl: null, storeCount: '200+ stores', countryCode: 'UK'),
]);

final homeStoresProvider = Provider<List<StoreItem>>((_) => [
  const StoreItem(id: 'amazon', name: 'Amazon', category: 'GLOBAL SHOP', logoUrl: null),
  const StoreItem(id: 'zara', name: 'Zara', category: 'FASHION', logoUrl: null),
  const StoreItem(id: 'nike', name: 'Nike', category: 'SPORTSWEAR', logoUrl: null),
  const StoreItem(id: 'sephora', name: 'Sephora', category: 'BEAUTY', logoUrl: null),
]);

final cartBadgeCountProvider = StateProvider<int>((_) => 2);
