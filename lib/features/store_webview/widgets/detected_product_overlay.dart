import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../models/detected_product.dart';

/// Bottom overlay shown when PDP is detected in WebView.
/// Slide-up animation with rounded top, product summary, and CTAs.
class DetectedProductOverlay extends StatefulWidget {
  const DetectedProductOverlay({
    super.key,
    required this.product,
    required this.appName,
    required this.onAddToCart,
    required this.onFavorite,
  });

  final DetectedProduct product;
  /// From bootstrap (admin) app name — shown in "Detected by …" header.
  final String appName;
  final VoidCallback onAddToCart;
  final VoidCallback onFavorite;

  @override
  State<DetectedProductOverlay> createState() => _DetectedProductOverlayState();
}

class _DetectedProductOverlayState extends State<DetectedProductOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: AppSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConfig.radiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(),
                _buildHeader(),
                const Divider(height: 1),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppConfig.borderColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppConfig.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'DETECTED BY ${widget.appName.toUpperCase()}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppConfig.successGreen,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product thumbnail
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: () {
              final url = resolveAssetUrl(widget.product.imageUrl, ApiClient.safeBaseUrl);
              return url != null && url.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      child: Image.network(
                        url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_outlined,
                          color: AppConfig.subtitleColor,
                          size: 32,
                        );
                      },
                    ),
                  )
                  : const Icon(
                    Icons.image_outlined,
                    color: AppConfig.subtitleColor,
                    size: 32,
                  );
            }(),
            ),
          const SizedBox(width: AppSpacing.md),
          // Product info + CTAs
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title ?? 'Product',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (widget.product.price != null)
                  Text(
                    'USD ${widget.product.price!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppConfig.primaryColor,
                        ),
                  ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)?.shippingReviewNoteShort ??
                      'Note: Shipping cost is subject to admin review.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onAddToCart,
                        icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                        label: Text('Add to ${widget.appName} Cart'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppConfig.radiusSmall),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppConfig.borderColor),
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                      child: IconButton(
                        onPressed: widget.onFavorite,
                        icon: const Icon(Icons.favorite_border, size: 22),
                        color: AppConfig.textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
