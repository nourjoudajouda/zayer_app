import '../models/detected_product.dart';
import '../../../core/import/normalize_url.dart';

/// PDP detection result.
class PdpDetectionResult {
  const PdpDetectionResult({
    required this.isPdp,
    this.product,
  });

  final bool isPdp;
  final DetectedProduct? product;

  static const PdpDetectionResult notPdp = PdpDetectionResult(isPdp: false);
}

/// Rule-based engine for detecting Product Detail Pages across stores.
/// Backend should provide these rules via config. For MVP, hardcoded.
class WebViewImportRules {
  /// Detect if the current URL is a PDP and extract product info.
  static PdpDetectionResult detectPdp(String url) {
    if (url.isEmpty) return PdpDetectionResult.notPdp;

    final normalized = normalizeProductUrl(url);

    // Amazon: /dp/{ASIN} or /gp/product/{ASIN}
    if (normalized.storeKey == 'amazon') {
      if (_isAmazonPdp(url)) {
        return PdpDetectionResult(
          isPdp: true,
          product: DetectedProduct.mockAmazon(
            normalized.canonicalUrl,
            asin: normalized.productId,
          ),
        );
      }
    }

    // eBay: /itm/{id}
    if (normalized.storeKey == 'ebay') {
      if (_isEbayPdp(url)) {
        return PdpDetectionResult(
          isPdp: true,
          product: DetectedProduct.mockEbay(url),
        );
      }
    }

    // Walmart: /ip/{product-name}
    if (normalized.storeKey == 'walmart') {
      if (_isWalmartPdp(url)) {
        return PdpDetectionResult(
          isPdp: true,
          product: DetectedProduct.mockWalmart(
            normalized.canonicalUrl,
            productId: normalized.productId,
          ),
        );
      }
    }

    // Etsy: /listing/{id}
    if (normalized.storeKey == 'etsy') {
      if (_isEtsyPdp(url)) {
        return PdpDetectionResult(
          isPdp: true,
          product: DetectedProduct.mockEtsy(
            normalized.canonicalUrl,
            listingId: normalized.productId,
          ),
        );
      }
    }

    // AliExpress: /item/{id}.html
    if (normalized.storeKey == 'aliexpress') {
      if (_isAliExpressPdp(url)) {
        return PdpDetectionResult(
          isPdp: true,
          product: DetectedProduct.mockAliExpress(
            normalized.canonicalUrl,
            itemId: normalized.productId,
          ),
        );
      }
    }

    return PdpDetectionResult.notPdp;
  }

  /// Amazon PDP patterns: /dp/, /gp/product/, /product/
  static bool _isAmazonPdp(String url) {
    final lower = url.toLowerCase();
    // Exclude search pages, category pages, homepage
    if (lower.contains('/s?') ||
        lower.contains('/b/') && lower.contains('node=') ||
        lower == 'https://www.amazon.com' ||
        lower == 'https://www.amazon.com/' ||
        lower.contains('/gp/bestsellers') ||
        lower.contains('/gp/new-releases')) {
      return false;
    }
    return lower.contains('/dp/') ||
        lower.contains('/gp/product/') ||
        lower.contains('/product/');
  }

  /// eBay PDP pattern: /itm/
  static bool _isEbayPdp(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/itm/');
  }

  /// Walmart PDP pattern: /ip/
  static bool _isWalmartPdp(String url) {
    final lower = url.toLowerCase();
    // Exclude search pages and category pages
    if (lower.contains('/search/') || lower.contains('/browse/')) {
      return false;
    }
    return lower.contains('/ip/');
  }

  /// Etsy PDP pattern: /listing/
  static bool _isEtsyPdp(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/listing/');
  }

  /// AliExpress PDP pattern: /item/
  static bool _isAliExpressPdp(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/item/') && lower.contains('.html');
  }
}
