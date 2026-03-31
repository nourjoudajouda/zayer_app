import 'package:dio/dio.dart';

import '../../../core/import/normalize_url.dart';
import '../../../core/network/api_client.dart';
import '../../product_import/models/product_variation.dart';
import '../models/product_import_result.dart';
import 'product_link_import_repository.dart';

/// API implementation: POST /api/products/import-from-url
class ProductLinkImportRepositoryApi implements ProductLinkImportRepository {
  ProductLinkImportRepositoryApi({Dio? dio}) : _dio = dio ?? ApiClient.instance;
  final Dio _dio;

  @override
  Future<ProductImportResult> fetchByUrl(String url) async {
    final normalized = normalizeProductUrl(url);
    if (normalized.canonicalUrl.isEmpty) {
      throw InvalidLinkException();
    }
    final u = Uri.tryParse(normalized.canonicalUrl);
    if (u == null || (u.scheme != 'http' && u.scheme != 'https')) {
      throw InvalidLinkException();
    }

    final res = await _dio.post<Map<String, dynamic>>(
      '/api/products/import-from-url',
      data: {'url': normalized.canonicalUrl},
    );

    final d = res.data;
    if (d == null) throw UnsupportedLinkException('No product data returned');

    List<ProductVariation>? variations;
    final vList = d['variations'];
    if (vList is List && vList.isNotEmpty) {
      variations = vList
          .map((e) => e is Map ? ProductVariation.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<ProductVariation>()
          .toList();
      if (variations.isEmpty) variations = null;
    }

    // Parse shipping quote if available
    ShippingQuotePreview? shippingQuote;
    final sq = d['shipping_quote'];
    if (sq is Map<String, dynamic>) {
      shippingQuote = ShippingQuotePreview.fromJson(sq);
    }

    return ProductImportResult(
      name: (d['name'] ?? 'Product').toString(),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      storeName: (d['store_name'] ?? 'Unknown').toString(),
      country: (d['country'] ?? 'Unknown').toString(),
      imageUrl: d['image_url'] as String?,
      canonicalUrl: d['canonical_url'] as String? ?? normalized.canonicalUrl,
      variations: variations,
      shippingQuote: shippingQuote,
      shippingReviewRequired: d['shipping_review_required'] != false,
      shippingNoteAr: d['shipping_note_ar'] as String?,
      shippingNoteEn: d['shipping_note_en'] as String?,
      extractionSource: d['extraction_source'] as String?,
    );
  }
}
