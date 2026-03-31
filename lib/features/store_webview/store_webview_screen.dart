import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/platform/webview_supported.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/favorites/providers/favorites_providers.dart';
import '../../features/paste_link/models/product_import_result.dart';
import '../../features/paste_link/providers/paste_link_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import 'extractors/product_data_extractor.dart';
import 'models/detected_product.dart';
import 'rules/webview_import_rules.dart';
import 'widgets/detected_product_overlay.dart';

class StoreWebViewScreen extends ConsumerStatefulWidget {
  const StoreWebViewScreen({
    super.key,
    required this.initialUrl,
  });

  final String initialUrl;

  @override
  ConsumerState<StoreWebViewScreen> createState() => _StoreWebViewScreenState();
}

class _StoreWebViewScreenState extends ConsumerState<StoreWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  DetectedProduct? _detectedProduct;
  bool _isExtractingProduct = false;
  bool _showExtractionLoader = false;
  /// Full import result from API (contains shipping quote, review flags).
  ProductImportResult? _importResult;

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
        ..addJavaScriptChannel(
          'ProductExtractor',
          onMessageReceived: (JavaScriptMessage message) {
            _handleProductData(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _isLoading = true;
                _detectedProduct = null;
                _importResult = null;
                _showExtractionLoader = false;
                _isExtractingProduct = false;
              });
              // Don't check PDP on page start, wait for page to finish
            },
            onPageFinished: (url) {
              setState(() => _isLoading = false);
              // Wait a bit for page to fully render before detecting PDP
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _checkPdp(url);
                }
              });
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

  void _checkPdp(String url) async {
    if (!mounted) return;
    
    debugPrint('🔍 Checking PDP for URL: $url');
    final result = WebViewImportRules.detectPdp(url);
    
    if (result.isPdp && result.product != null) {
      debugPrint('✅ PDP detected: ${result.product!.storeKey}');
      
      // Show overlay immediately with detected product (will show loader)
      if (mounted) {
        setState(() {
          _detectedProduct = result.product;
          _showExtractionLoader = true; // Show loader immediately
          _isExtractingProduct = true;
        });
      }
      
      // Small delay to ensure overlay is rendered
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) {
        debugPrint('⚠️ Widget unmounted during PDP check delay');
        _hideLoader();
        return;
      }
      
      // 1) Fetch product from API first (name, image, price in USD) — show loader until done
      final repo = ref.read(productLinkImportRepositoryProvider);
      try {
        final apiResult = await repo.fetchByUrl(url);
        if (!mounted) {
          _hideLoader();
          return;
        }
        final updatedFromApi = DetectedProduct(
          storeKey: result.product!.storeKey,
          storeName: apiResult.storeName,
          productUrl: apiResult.canonicalUrl ?? url,
          title: apiResult.name,
          price: apiResult.price,
          currency: 'USD',
          imageUrl: apiResult.imageUrl,
          productId: result.product!.productId,
          variations: apiResult.variations,
        );
        setState(() {
          _detectedProduct = updatedFromApi;
          _importResult = apiResult;
          _showExtractionLoader = false;
          _isExtractingProduct = false;
        });
        return;
      } catch (_) {
        // API failed — fall back to JS extraction or use detected product as-is
        if (!mounted) {
          _hideLoader();
          return;
        }
      }
      
      // 2) Fallback: try JS extraction if available
      final storeKey = result.product!.storeKey;
      final extractionScript = ProductDataExtractor.getExtractionScript(storeKey);
      
      if (extractionScript != null && _controller != null) {
        debugPrint('📝 Fallback: extraction script for $storeKey');
        await _extractProductData(result.product!, extractionScript);
      } else {
        if (mounted) {
          setState(() {
            _showExtractionLoader = false;
            _isExtractingProduct = false;
          });
        }
      }
    } else {
      debugPrint('❌ Not a PDP or product is null');
      if (mounted) {
        setState(() {
          _detectedProduct = null;
          _showExtractionLoader = false;
          _isExtractingProduct = false;
        });
      }
    }
  }

  Future<void> _extractProductData(DetectedProduct detectedProduct, String extractionScript) async {
    if (_controller == null || !mounted) {
      _hideLoader();
      return;
    }
    
    // Reset extraction state to allow retry
    if (_isExtractingProduct) {
      debugPrint('Previous extraction still in progress, resetting...');
      _hideLoader();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!mounted) {
      _hideLoader();
      return;
    }
    
    // Ensure loader is shown before starting extraction
    if (mounted) {
      setState(() {
        _isExtractingProduct = true;
        _showExtractionLoader = true;
      });
    }

    try {
      debugPrint('Starting product data extraction for ${detectedProduct.storeKey}');
      
      // Wait a bit to ensure DOM is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted || _controller == null) {
        debugPrint('Widget unmounted or controller null after delay');
        _hideLoader();
        return;
      }
      
      // Add timeout to prevent infinite loading
      debugPrint('Executing JavaScript extraction script...');
      final result = await _controller!
          .runJavaScriptReturningResult(extractionScript)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⚠️ JavaScript extraction timeout after 5 seconds');
              return '';
            },
          );
      
      if (!mounted) {
        debugPrint('Widget unmounted after JavaScript execution');
        _hideLoader();
        return;
      }
      
      final resultString = result.toString().trim();
      debugPrint('✅ Extraction result received: ${resultString.length > 100 ? "${resultString.substring(0, 100)}..." : resultString}');
      
      if (resultString.isNotEmpty && resultString != 'null' && resultString != 'undefined') {
        final productData = _parseProductData(resultString);
        
        if (productData != null && productData['success'] == true) {
          debugPrint('✅ Product data parsed successfully');
          
          // Convert price to double if it's a number
          double? price;
          final priceValue = productData['price'];
          if (priceValue != null) {
            if (priceValue is double) {
              price = priceValue;
            } else if (priceValue is int) {
              price = priceValue.toDouble();
            } else if (priceValue is String) {
              price = double.tryParse(priceValue);
            }
          }
          
          // Update detected product with real data
          final updatedProduct = DetectedProduct(
            storeKey: detectedProduct.storeKey,
            storeName: detectedProduct.storeName,
            productUrl: detectedProduct.productUrl,
            title: productData['title'] as String?,
            price: price,
            currency: productData['currency'] as String? ?? 'USD',
            imageUrl: productData['imageUrl'] as String?,
            productId: productData['productId'] as String? ?? detectedProduct.productId,
          );
          
          if (mounted) {
            debugPrint('✅ Hiding loader and updating product data');
            setState(() {
              _detectedProduct = updatedProduct;
              _isExtractingProduct = false;
              _showExtractionLoader = false; // Hide loader when data is ready
            });
          }
          return;
        } else {
          debugPrint('❌ Product data parsing failed or success=false');
          debugPrint('Parsed data: $productData');
          // Even if parsing fails, hide loader and show detected product
          _hideLoader();
          return;
        }
      } else {
        debugPrint('❌ Empty or null result from JavaScript extraction: "$resultString"');
        // Empty result - hide loader and show detected product
        _hideLoader();
        return;
      }
    } catch (e, stackTrace) {
      // If extraction fails, fall back to detected product
      debugPrint('❌ Exception during product extraction: $e');
      debugPrint('Stack trace: $stackTrace');
      // Always hide loader on error
      _hideLoader();
    }
  }

  void _hideLoader() {
    if (mounted) {
      debugPrint('🔄 Hiding extraction loader');
      setState(() {
        _isExtractingProduct = false;
        _showExtractionLoader = false;
      });
    } else {
      debugPrint('⚠️ Cannot hide loader - widget not mounted');
    }
  }

  Map<String, dynamic>? _parseProductData(String jsonString) {
    try {
      String cleaned = jsonString.trim();
      
      // Handle null or empty
      if (cleaned.isEmpty || cleaned == 'null' || cleaned == 'undefined') {
        return null;
      }
      
      // Remove surrounding quotes if present
      if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
        // Unescape JSON string
        cleaned = cleaned.replaceAll('\\"', '"');
        cleaned = cleaned.replaceAll('\\n', '\n');
        cleaned = cleaned.replaceAll('\\r', '\r');
        cleaned = cleaned.replaceAll('\\t', '\t');
        cleaned = cleaned.replaceAll('\\\\', '\\');
      }
      
      // Try to parse as JSON
      final decoded = json.decode(cleaned) as Map<String, dynamic>;
      return decoded;
    } catch (e) {
      debugPrint('Failed to parse product data: $e');
      debugPrint('Raw string: $jsonString');
      return null;
    }
  }

  void _handleProductData(String message) {
    // Handle message from JavaScript channel if needed
    debugPrint('Product data received: $message');
  }

  void _handleAddToCart() {
    if (_detectedProduct != null) {
      final productJson = jsonEncode({
        'storeKey': _detectedProduct!.storeKey,
        'storeName': _detectedProduct!.storeName,
        'productUrl': _detectedProduct!.productUrl,
        'title': _detectedProduct!.title,
        'price': _detectedProduct!.price,
        'currency': _detectedProduct!.currency,
        'imageUrl': _detectedProduct!.imageUrl,
        'productId': _detectedProduct!.productId,
        if (_detectedProduct!.variations != null && _detectedProduct!.variations!.isNotEmpty)
          'variations': _detectedProduct!.variations!.map((v) => v.toJson()).toList(),
      });

      context.push(
        '${AppRoutes.confirmProduct}?url=${Uri.encodeComponent(_detectedProduct!.productUrl)}&product=${Uri.encodeComponent(productJson)}',
        extra: _importResult,
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
      builder: (context) => _SaveFavoriteSheet(product: _detectedProduct!, ref: ref),
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
        if (_detectedProduct == null && !_isLoading && !_showExtractionLoader)
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
              appName: ref.watch(appDisplayNameProvider),
              onAddToCart: _handleAddToCart,
              onFavorite: _handleFavorite,
              isExtracting: _showExtractionLoader,
            ),
          ),
      ],
    );
  }

  Widget _buildHintBanner() {
    final appName = ref.watch(appDisplayNameProvider);
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
                'Open a product page to add items to your $appName cart.',
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

/// Save product to favorites via API.
class _SaveFavoriteSheet extends StatefulWidget {
  const _SaveFavoriteSheet({required this.product, required this.ref});

  final DetectedProduct product;
  final WidgetRef ref;

  @override
  State<_SaveFavoriteSheet> createState() => _SaveFavoriteSheetState();
}

class _SaveFavoriteSheetState extends State<_SaveFavoriteSheet> {
  bool _isFavorited = false;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_isFavorited) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/favorites',
        data: {
          'source_key': widget.product.storeKey,
          'source_label': widget.product.storeName,
          'title': widget.product.title ?? 'Product',
          'price': widget.product.price ?? 0,
          'currency': widget.product.currency,
          'image_url': widget.product.imageUrl,
          'product_url': widget.product.productUrl,
        },
      );
      widget.ref.invalidate(favoritesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: AppConfig.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to favorites')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
                child: () {
                  final url = resolveAssetUrl(widget.product.imageUrl, ApiClient.safeBaseUrl);
                  return url != null && url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppConfig.borderColor.withValues(alpha: 0.3),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image_outlined,
                              color: AppConfig.subtitleColor,
                              size: 32,
                            ),
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
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isFavorited ? 'Add to favorites' : 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
