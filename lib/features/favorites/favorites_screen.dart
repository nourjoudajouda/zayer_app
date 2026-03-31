import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import 'models/favorite_item.dart';
import 'providers/favorites_providers.dart';
import 'favorites_empty_screen.dart';

/// Favorites list with price tracking. Shows empty state or list with filter chips and cards.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredFavoritesProvider);
    final items = itemsAsync.valueOrNull ?? [];
    final filter = ref.watch(favoritesFilterProvider);

    if (itemsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return const FavoritesEmptyScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConfig.textColor),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.star, color: AppConfig.primaryColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Favorites',
                      style: AppTextStyles.titleLarge(AppConfig.textColor),
                    ),
                    Text(
                      'Price tracking & availability alerts.',
                      style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: AppConfig.textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Items',
                      selected: filter == FavoritesFilter.all,
                      onTap: () => ref.read(favoritesFilterProvider.notifier).state = FavoritesFilter.all,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'Price Drops',
                      selected: filter == FavoritesFilter.priceDrops,
                      icon: Icons.show_chart,
                      iconColor: AppConfig.successGreen,
                      onTap: () => ref.read(favoritesFilterProvider.notifier).state = FavoritesFilter.priceDrops,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: 'In Stock',
                      selected: filter == FavoritesFilter.inStock,
                      onTap: () => ref.read(favoritesFilterProvider.notifier).state = FavoritesFilter.inStock,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(favoritesListProvider);
                  await ref.read(favoritesListProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _FavoriteCard(item: items[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppConfig.primaryColor : AppConfig.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: selected ? Colors.white : (iconColor ?? AppConfig.subtitleColor)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.bodyMedium(selected ? Colors.white : AppConfig.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.item});

  final FavoriteItem item;

  Future<void> _removeFavorite(WidgetRef ref, BuildContext context) async {
    ref.read(loadingFavoriteIdProvider.notifier).state = item.id;
    try {
      await ApiClient.instance.delete<void>('/api/favorites/${item.id}');
      ref.invalidate(favoritesListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppConfig.successGreen,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from favorites')),
        );
      }
    } finally {
      ref.read(loadingFavoriteIdProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRemoving = ref.watch(loadingFavoriteIdProvider) == item.id;
    void onRemove() => _removeFavorite(ref, context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SourceIcon(sourceKey: item.sourceKey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.sourceLabel,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: AppTextStyles.titleMedium(AppConfig.textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        item.priceFormatted,
                        style: AppTextStyles.titleLarge(AppConfig.textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.priceDrop != null && item.priceDrop! > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.show_chart, size: 16, color: AppConfig.successGreen),
                      const SizedBox(width: 2),
                      Text(
                        '↘ ${item.currency}${item.priceDrop!.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall(AppConfig.successGreen),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      item.trackingOn ? Icons.notifications_active : Icons.notifications_off,
                      size: 16,
                      color: item.trackingOn ? AppConfig.primaryColor : AppConfig.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.trackingOn ? 'Tracking On' : 'Alerts Off',
                        style: AppTextStyles.bodySmall(item.trackingOn ? AppConfig.textColor : AppConfig.subtitleColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      item.stockStatus == FavoriteStockStatus.outOfStock ? Icons.error_outline : Icons.check_circle_outline,
                      size: 16,
                      color: item.stockStatus == FavoriteStockStatus.inStock
                          ? AppConfig.successGreen
                          : item.stockStatus == FavoriteStockStatus.outOfStock
                              ? AppConfig.errorRed
                              : AppConfig.subtitleColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.stockLabel,
                        style: AppTextStyles.bodySmall(
                          item.stockStatus == FavoriteStockStatus.inStock
                              ? AppConfig.successGreen
                              : item.stockStatus == FavoriteStockStatus.outOfStock
                                  ? AppConfig.errorRed
                                  : AppConfig.subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      item.isOutOfStock ? Icons.notifications_active_outlined : Icons.shopping_cart_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      item.isOutOfStock ? 'Notify me when available' : 'Add to Zayer Cart',
                      style: AppTextStyles.bodyMedium(Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: item.isOutOfStock ? AppConfig.subtitleColor : AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isRemoving ? null : onRemove,
                icon: isRemoving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.favorite, color: AppConfig.primaryColor, size: 24),
                tooltip: 'Remove from favorites',
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppConfig.borderColor.withValues(alpha: 0.5),
                  child: () {
                    final url = resolveAssetUrl(item.imageUrl, ApiClient.safeBaseUrl);
                    return url != null && url.isNotEmpty
                        ? Image.network(url, fit: BoxFit.cover)
                        : Icon(Icons.image_outlined, size: 32, color: AppConfig.subtitleColor);
                  }(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.sourceKey});

  final String sourceKey;

  @override
  Widget build(BuildContext context) {
    final isAmazon = sourceKey.toLowerCase() == 'amazon';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isAmazon ? AppConfig.warningOrange : AppConfig.textColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isAmazon ? 'a' : 'S',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
