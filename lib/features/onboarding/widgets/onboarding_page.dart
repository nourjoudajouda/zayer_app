import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/models/app_bootstrap_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Content only: image + title + description. No button (button is below PageView).
/// Layout is scroll-safe to prevent BOTTOM OVERFLOWED; image has min/max height.
class OnboardingPageWidget extends StatelessWidget {
  const OnboardingPageWidget({
    super.key,
    required this.pageConfig,
    required this.lang,
  });

  final OnboardingPageConfig pageConfig;
  final String lang;

  static const double _imageMinHeight = 200;
  static const double _imageMaxHeight = 320;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            _buildImage(context, pageConfig.imageUrl),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pageConfig.title(lang),
                      style: AppTextStyles.headlineMedium(AppConfig.textColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      pageConfig.description(lang),
                      style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String imageUrl) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight =
        (screenHeight * 0.35).clamp(_imageMinHeight, _imageMaxHeight);

    return Container(
      height: imageHeight,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
        color: AppConfig.borderColor.withValues(alpha: 0.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
        child: imageUrl.isEmpty
            ? _buildImagePlaceholder()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      color: AppConfig.borderColor.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppConfig.subtitleColor,
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      color: AppConfig.borderColor.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppConfig.subtitleColor,
        ),
      ),
    );
  }
}
