import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/config/models/app_bootstrap_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Store card: logo, name, description, VISIT STORE button.
class FeaturedStoreCard extends StatelessWidget {
  const FeaturedStoreCard({super.key, required this.store});

  final StoreConfig store;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppConfig.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: () {
                final url = resolveAssetUrl(store.logoUrl, ApiClient.safeBaseUrl);
                return url != null && url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.store,
                          color: AppConfig.subtitleColor,
                          size: 28,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.store,
                          color: AppConfig.subtitleColor,
                          size: 28,
                        ),
                      ),
                    )
                    : const Icon(Icons.store, color: AppConfig.subtitleColor, size: 28);
              }(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppConfig.textColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () {
                context.push(
                  '${AppRoutes.storeLanding}'
                  '?storeId=${Uri.encodeComponent(store.id)}'
                  '&storeName=${Uri.encodeComponent(store.name)}'
                  '&storeUrl=${Uri.encodeComponent(store.storeUrl)}'
                  '&logoUrl=${Uri.encodeComponent(store.logoUrl)}'
                  '&categories=${Uri.encodeComponent(store.categories.join(','))}',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                ),
              ),
              child: const Text('VISIT STORE'),
            ),
          ],
        ),
      ),
    );
  }
}
