import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/platform/webview_supported.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import 'models/detected_product.dart';
import 'rules/webview_import_rules.dart';
import 'widgets/detected_product_overlay.dart';

class StoreWebViewScreen extends StatefulWidget {
  const StoreWebViewScreen({
    super.key,
    required this.initialUrl,
  });

  final String initialUrl;

  @override
  State<StoreWebViewScreen> createState() => _StoreWebViewScreenState();
}

class _StoreWebViewScreenState extends State<StoreWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  DetectedProduct? _detectedProduct;

  String get _resolvedUrl =>
      widget.initialUrl.trim().isNotEmpty
          ? widget.initialUrl
          : 'https://www.amazon.com';

  @override
  void initState() {
    super.initState();
    if (isWebViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _isLoading = true);
              _checkPdp(url);
            },
            onPageFinished: (url) {
              setState(() => _isLoading = false);
              _checkPdp(url);
            },
            onNavigationRequest: (request) {
              _checkPdp(request.url);
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_resolvedUrl));
    }
  }

  void _checkPdp(String url) {
    final result = WebViewImportRules.detectPdp(url);
    setState(() {
      _detectedProduct = result.isPdp ? result.product : null;
    });
  }

  void _handleAddToCart() {
    if (_detectedProduct != null) {
      context.push(
        '${AppRoutes.confirmProduct}?url=${Uri.encodeComponent(_detectedProduct!.productUrl)}',
      );
    }
  }

  void _handleFavorite() {
    if (_detectedProduct != null) {
      _showSaveFavoriteSheet();
    }
  }

  void _showSaveFavoriteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveFavoriteSheet(product: _detectedProduct!),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_resolvedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Builder(
          builder: (context) => Text(AppLocalizations.of(context)!.store),
        ),
      ),
      body: isWebViewSupported && _controller != null
          ? _buildWebViewBody()
          : _buildFallbackBody(),
    );
  }

  /// Fallback when WebView is not supported (Windows, Linux, Web).
  Widget _buildFallbackBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web_asset_outlined,
              size: 64,
              color: AppConfig.subtitleColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'WebView is supported on Android/iOS only.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Run on an Android emulator or iOS device to browse stores in-app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SelectableText(
              _resolvedUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    decoration: TextDecoration.underline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in browser'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewBody() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (_detectedProduct == null && !_isLoading)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildHintBanner(),
          ),
        if (_detectedProduct != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DetectedProductOverlay(
              product: _detectedProduct!,
              onAddToCart: _handleAddToCart,
              onFavorite: _handleFavorite,
            ),
          ),
      ],
    );
  }

  Widget _buildHintBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg,
        border: Border(
          top: BorderSide(color: AppConfig.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: AppConfig.primaryColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Open a product page to add items to your Zayer cart.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.textColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock Save Favorite sheet (UI only).
class _SaveFavoriteSheet extends StatefulWidget {
  const _SaveFavoriteSheet({required this.product});

  final DetectedProduct product;

  @override
  State<_SaveFavoriteSheet> createState() => _SaveFavoriteSheetState();
}

class _SaveFavoriteSheetState extends State<_SaveFavoriteSheet> {
  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConfig.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Save to Favorites',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppConfig.subtitleColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title ?? 'Product',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.storeName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConfig.subtitleColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              value: _isFavorited,
              onChanged: (val) => setState(() => _isFavorited = val),
              title: const Text('Add to favorites'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isFavorited ? 'Added to favorites (mock)' : 'Saved (mock)',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
