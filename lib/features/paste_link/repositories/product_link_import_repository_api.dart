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
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 90),
      ),
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

    // Parse shipping estimate (required normalized block)
    ShippingEstimate? shippingEstimate;
    final se = d['shipping_estimate'];
    if (se is Map<String, dynamic>) {
      shippingEstimate = ShippingEstimate.fromJson(se);
    }

    // Parse measurements (do not fake)
    final weight = (d['weight'] as num?)?.toDouble();
    ProductDimensions? dimsData;
    String? dimsFormatted;
    final dims = d['dimensions'];
    if (dims is Map) {
      dimsData = ProductDimensions.fromJson(Map<String, dynamic>.from(dims));
      if (dimsData.hasAnyDimension) dimsFormatted = dimsData.format();
    } else if (dims is String) {
      dimsFormatted = dims.trim().isNotEmpty ? dims.trim() : null;
    }
    // Fallback: accept flat L/W/H when any dimension is present (partial OK).
    if ((dimsData == null || !dimsData.hasAnyDimension) &&
        (d['length'] is num || d['width'] is num || d['height'] is num)) {
      final unit = (d['dimension_unit'] as String?) ??
          (d['dimensions_unit'] as String?) ??
          'cm';
      final tmp = ProductDimensions(
        length: d['length'] is num ? (d['length'] as num).toDouble() : null,
        width: d['width'] is num ? (d['width'] as num).toDouble() : null,
        height: d['height'] is num ? (d['height'] as num).toDouble() : null,
        unit: unit,
      );
      if (tmp.hasAnyDimension) {
        dimsData = tmp;
        final f = tmp.format();
        if (f.isNotEmpty) dimsFormatted = f;
      }
    }

    return ProductImportResult(
      name: (d['name'] ?? 'Product').toString(),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      storeKey: d['store_key'] as String?,
      storeName: (d['store_name'] ?? 'Unknown').toString(),
      country: (d['country'] ?? 'Unknown').toString(),
      imageUrl: d['image_url'] as String?,
      weight: weight,
      weightUnit: d['weight_unit'] as String?,
      dimensions: dimsFormatted,
      dimensionsData: dimsData,
      canonicalUrl: d['canonical_url'] as String? ?? normalized.canonicalUrl,
      variations: variations,
      shippingQuote: shippingQuote,
      shippingEstimate: shippingEstimate,
      shippingReviewRequired: d['shipping_review_required'] == true,
      shippingNoteAr: d['shipping_note_ar'] as String?,
      shippingNoteEn: d['shipping_note_en'] as String?,
      extractionSource: d['extraction_source'] as String?,
      measurementsFound: d['measurements_found'] == true,
      shippingEstimateSource: d['shipping_estimate_source'] as String?,
      appFeePercent: (d['app_fee_percent'] as num?)?.toDouble() ?? 0,
      appFeeAmount: (d['app_fee_amount'] as num?)?.toDouble() ?? 0,
      payableNowTotal: (d['payable_now_total'] as num?)?.toDouble() ?? 0,
      shippingPayableNow: (d['shipping_payable_now'] as num?)?.toInt() ?? 0,
    );
  }
}
