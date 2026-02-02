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

  /// Future stores can be added here:
  /// - Walmart: /ip/
  /// - Etsy: /listing/
  /// - AliExpress: /item/
}
