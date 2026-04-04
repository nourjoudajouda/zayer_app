import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Compact bottom strip shown while product metadata is being fetched on PDP.
class CollectingProductBanner extends StatelessWidget {
  const CollectingProductBanner({
    super.key,
    this.appIconUrl,
  });

  final String? appIconUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resolved = resolveAssetUrl(appIconUrl, ApiClient.safeBaseUrl);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _Logo(appIconUrl: resolved),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n?.collectingProductInformation ??
                        'Collecting product information…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConfig.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.appIconUrl});

  final String? appIconUrl;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (appIconUrl != null && appIconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: appIconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _placeholder(size),
          errorWidget: (context, url, error) => _placeholder(size),
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Icon(
        Icons.storefront_rounded,
        color: AppConfig.primaryColor,
        size: size * 0.5,
      ),
    );
  }
}
