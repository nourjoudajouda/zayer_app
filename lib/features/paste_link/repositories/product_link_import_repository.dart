import '../../../core/import/normalize_url.dart';
import '../models/product_import_result.dart';

/// Fetches product metadata from a product URL. Replace with API later.
abstract class ProductLinkImportRepository {
  Future<ProductImportResult> fetchByUrl(String url);
}

/// Mock implementation. Replace with real API (POST /api/product-import/preview).
/// Uses normalizeProductUrl for canonicalization. Backend should return canonical_url in preview response.
class ProductLinkImportRepositoryMock implements ProductLinkImportRepository {
  @override
  Future<ProductImportResult> fetchByUrl(String url) async {
    final normalized = normalizeProductUrl(url);

    if (normalized.canonicalUrl.isEmpty || !_isValidHttpUrl(normalized.canonicalUrl)) {
      throw InvalidLinkException();
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final lower = url.toLowerCase();
    if (lower.contains('invalid')) {
      throw InvalidLinkException();
    }

    if (normalized.storeKey == 'amazon' && normalized.productId != null) {
      final asin = normalized.productId!;
      return ProductImportResult(
        name: 'HP 14" Laptop (ASIN $asin)',
        price: 499.99,
        storeName: 'Amazon US',
        country: 'USA',
        imageUrl: null,
        weight: null,
        dimensions: null,
        canonicalUrl: normalized.canonicalUrl,
      );
    }

    if (normalized.storeKey == 'amazon') {
      return const ProductImportResult(
        name: 'Amazon Product',
        price: 49.99,
        storeName: 'Amazon US',
        country: 'USA',
        imageUrl: null,
        weight: null,
        dimensions: null,
        canonicalUrl: null,
      );
    }

    if (normalized.storeKey == 'ebay') {
      return ProductImportResult(
        name: 'eBay Item',
        price: 89.00,
        storeName: 'eBay US',
        country: 'USA',
        imageUrl: null,
        weight: null,
        dimensions: null,
        canonicalUrl: normalized.canonicalUrl,
      );
    }

    throw UnsupportedLinkException();
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
