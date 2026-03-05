import 'package:dio/dio.dart';

import '../../../core/import/normalize_url.dart';
import '../../../core/network/api_client.dart';
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

    return ProductImportResult(
      name: (d['name'] ?? 'Product').toString(),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      storeName: (d['store_name'] ?? 'Unknown').toString(),
      country: (d['country'] ?? 'Unknown').toString(),
      imageUrl: d['image_url'] as String?,
      canonicalUrl: d['canonical_url'] as String? ?? normalized.canonicalUrl,
    );
  }
}
