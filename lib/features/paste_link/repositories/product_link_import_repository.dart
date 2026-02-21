import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/import/normalize_url.dart';
import '../../store_webview/extractors/product_data_extractor.dart';
import '../../store_webview/models/detected_product.dart';
import '../../store_webview/rules/webview_import_rules.dart';
import '../models/product_import_result.dart';

/// Fetches product metadata from a product URL. Replace with API later.
abstract class ProductLinkImportRepository {
  Future<ProductImportResult> fetchByUrl(String url);
}

/// Implementation that uses WebView to extract real product data from URLs.
/// Uses the same extraction logic as the WebView import feature.
class ProductLinkImportRepositoryMock implements ProductLinkImportRepository {
  @override
  Future<ProductImportResult> fetchByUrl(String url) async {
    final normalized = normalizeProductUrl(url);

    if (normalized.canonicalUrl.isEmpty || !_isValidHttpUrl(normalized.canonicalUrl)) {
      throw InvalidLinkException();
    }

    // Check if URL is a PDP
    final pdpResult = WebViewImportRules.detectPdp(normalized.canonicalUrl);
    
    if (!pdpResult.isPdp || pdpResult.product == null) {
      throw UnsupportedLinkException('This URL does not appear to be a product page');
    }

    final detectedProduct = pdpResult.product!;
    final storeKey = detectedProduct.storeKey;

    // Check if we have an extraction script for this store
    final extractionScript = ProductDataExtractor.getExtractionScript(storeKey);
    
    if (extractionScript == null) {
      // No extraction script - use detected product data as fallback
      return _convertDetectedProductToResult(detectedProduct, normalized.canonicalUrl);
    }

    // Use WebView to extract real product data
    try {
      final extractedData = await _extractProductDataWithWebView(
        normalized.canonicalUrl,
        extractionScript,
      );

      if (extractedData != null && extractedData['success'] == true) {
        // Convert price to double
        double? price;
        final priceValue = extractedData['price'];
        if (priceValue != null) {
          if (priceValue is double) {
            price = priceValue;
          } else if (priceValue is int) {
            price = priceValue.toDouble();
          } else if (priceValue is String) {
            price = double.tryParse(priceValue);
          }
        }

        return ProductImportResult(
          name: extractedData['title'] as String? ?? detectedProduct.title ?? 'Product',
          price: price ?? detectedProduct.price ?? 0.0,
          storeName: detectedProduct.storeName,
          country: _getCountryFromStoreKey(storeKey),
          imageUrl: extractedData['imageUrl'] as String? ?? detectedProduct.imageUrl,
          weight: null,
          dimensions: null,
          canonicalUrl: normalized.canonicalUrl,
        );
      } else {
        // Extraction failed - use detected product as fallback
        return _convertDetectedProductToResult(detectedProduct, normalized.canonicalUrl);
      }
    } catch (e) {
      debugPrint('Failed to extract product data: $e');
      // Fallback to detected product
      return _convertDetectedProductToResult(detectedProduct, normalized.canonicalUrl);
    }
  }

  /// Extract product data using a hidden WebView
  Future<Map<String, dynamic>?> _extractProductDataWithWebView(
    String url,
    String extractionScript,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('WebView extraction not supported on this platform');
      return null;
    }

    try {
      debugPrint('🔍 Starting WebView extraction for: $url');
      
      // Use Completer to wait for page to finish loading
      final pageLoadedCompleter = Completer<void>();

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              debugPrint('📄 Page started loading: $url');
            },
            onPageFinished: (url) {
              debugPrint('✅ Page finished loading: $url');
              if (!pageLoadedCompleter.isCompleted) {
                pageLoadedCompleter.complete();
              }
            },
            onWebResourceError: (error) {
              debugPrint('❌ WebView error: ${error.description}');
              if (!pageLoadedCompleter.isCompleted) {
                pageLoadedCompleter.completeError(error);
              }
            },
          ),
        );

      // Load the URL
      debugPrint('📥 Loading URL...');
      await controller.loadRequest(Uri.parse(url));

      // Wait for page to finish loading (with timeout)
      try {
        await pageLoadedCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('⚠️ Page load timeout after 15 seconds');
            if (!pageLoadedCompleter.isCompleted) {
              pageLoadedCompleter.complete();
            }
          },
        );
      } catch (e) {
        debugPrint('⚠️ Error waiting for page load: $e');
      }

      // Wait additional time for DOM to be ready
      debugPrint('⏳ Waiting for DOM to be ready...');
      await Future.delayed(const Duration(milliseconds: 1500));

      // Execute extraction script
      debugPrint('📝 Executing extraction script...');
      final result = await controller
          .runJavaScriptReturningResult(extractionScript)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ JavaScript extraction timeout after 10 seconds');
              return '';
            },
          );

      final resultString = result.toString().trim();
      debugPrint('📊 Extraction result: ${resultString.length > 200 ? "${resultString.substring(0, 200)}..." : resultString}');
      
      if (resultString.isNotEmpty && resultString != 'null' && resultString != 'undefined') {
        final parsed = _parseProductData(resultString);
        if (parsed != null && parsed['success'] == true) {
          debugPrint('✅ Successfully extracted product data');
        } else {
          debugPrint('❌ Failed to parse product data or success=false');
        }
        return parsed;
      } else {
        debugPrint('❌ Empty or null result from extraction');
      }

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error extracting product data: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Parse product data JSON string
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

  /// Convert DetectedProduct to ProductImportResult
  ProductImportResult _convertDetectedProductToResult(
    DetectedProduct product,
    String canonicalUrl,
  ) {
    return ProductImportResult(
      name: product.title ?? 'Product',
      price: product.price ?? 0.0,
      storeName: product.storeName,
      country: _getCountryFromStoreKey(product.storeKey),
      imageUrl: product.imageUrl,
      weight: null,
      dimensions: null,
      canonicalUrl: canonicalUrl,
    );
  }

  /// Get country name from store key
  String _getCountryFromStoreKey(String storeKey) {
    switch (storeKey) {
      case 'amazon':
        return 'USA';
      case 'ebay':
        return 'USA';
      case 'walmart':
        return 'USA';
      case 'etsy':
        return 'USA';
      case 'aliexpress':
        return 'China';
      default:
        return 'Unknown';
    }
  }

  bool _isValidHttpUrl(String url) {
    try {
      final u = Uri.parse(url);
      return u.scheme == 'http' || u.scheme == 'https';
    } catch (_) {
      return false;
    }
  }
}
