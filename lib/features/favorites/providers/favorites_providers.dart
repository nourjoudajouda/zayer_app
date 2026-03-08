import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/favorite_item.dart';

/// Filter for favorites list.
enum FavoritesFilter {
  all,
  priceDrops,
  inStock,
}

/// Favorites from API: GET /api/favorites
final favoritesListProvider = FutureProvider<List<FavoriteItem>>((ref) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/favorites');
    final list = res.data;
    if (list != null) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(FavoriteItem.fromJson)
          .toList();
    }
  } catch (_) {}
  return [];
});

final favoritesFilterProvider = StateProvider<FavoritesFilter>((ref) {
  return FavoritesFilter.all;
});

/// ID of the favorite item currently being removed (for button/card loader).
final loadingFavoriteIdProvider = StateProvider<String?>((ref) => null);

final filteredFavoritesProvider = Provider<AsyncValue<List<FavoriteItem>>>((ref) {
  final async = ref.watch(favoritesListProvider);
  final filter = ref.watch(favoritesFilterProvider);
  return async.when(
    data: (list) {
      switch (filter) {
        case FavoritesFilter.priceDrops:
          return AsyncValue.data(list.where((e) => e.priceDrop != null && e.priceDrop! > 0).toList());
        case FavoritesFilter.inStock:
          return AsyncValue.data(list.where((e) => e.stockStatus != FavoriteStockStatus.outOfStock).toList());
        case FavoritesFilter.all:
        default:
          return AsyncValue.data(list);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
