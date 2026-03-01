import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favorite_item.dart';

/// Filter for favorites list.
enum FavoritesFilter {
  all,
  priceDrops,
  inStock,
}

/// Mock list. Replace with API later.
final _mockItems = [
  FavoriteItem(
    id: '1',
    sourceKey: 'amazon',
    sourceLabel: 'FOUND ON AMAZON',
    title: 'Amazon Echo Dot (5th Gen) Deep Sea Blue',
    price: 44.99,
    currency: '€',
    priceDrop: 12,
    trackingOn: true,
    stockStatus: FavoriteStockStatus.inStock,
    stockLabel: 'In Stock',
    imageUrl: null,
  ),
  FavoriteItem(
    id: '2',
    sourceKey: 'shein',
    sourceLabel: 'FOUND ON SHEIN',
    title: 'Minimalist Oversized Cotton Hoodie',
    price: 22.50,
    currency: '€',
    priceDrop: 5,
    trackingOn: false,
    stockStatus: FavoriteStockStatus.lowStock,
    stockLabel: 'Low Stock (2 left)',
    imageUrl: null,
  ),
  FavoriteItem(
    id: '3',
    sourceKey: 'amazon',
    sourceLabel: 'FOUND ON AMAZON',
    title: 'Sony WH-1000XM5 Wireless Headphones',
    price: 329.00,
    currency: '€',
    priceDrop: null,
    trackingOn: true,
    stockStatus: FavoriteStockStatus.outOfStock,
    stockLabel: 'OUT OF STOCK',
    imageUrl: null,
  ),
];

final favoritesListProvider = Provider<List<FavoriteItem>>((ref) {
  return _mockItems;
});

final favoritesFilterProvider = StateProvider<FavoritesFilter>((ref) {
  return FavoritesFilter.all;
});

final filteredFavoritesProvider = Provider<List<FavoriteItem>>((ref) {
  final list = ref.watch(favoritesListProvider);
  final filter = ref.watch(favoritesFilterProvider);
  switch (filter) {
    case FavoritesFilter.priceDrops:
      return list.where((e) => e.priceDrop != null && e.priceDrop! > 0).toList();
    case FavoritesFilter.inStock:
      return list.where((e) => e.stockStatus != FavoriteStockStatus.outOfStock).toList();
    case FavoritesFilter.all:
    default:
      return list;
  }
});
