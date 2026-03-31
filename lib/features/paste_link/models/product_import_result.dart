import '../../product_import/models/product_variation.dart';

/// Result of fetching product metadata from a URL.
class ProductImportResult {
  const ProductImportResult({
    required this.name,
    required this.price,
    required this.storeName,
    required this.country,
    this.imageUrl,
    this.weight,
    this.dimensions,
    this.canonicalUrl,
    this.variations,
    this.shippingQuote,
    this.shippingReviewRequired = true,
    this.shippingNoteAr,
    this.shippingNoteEn,
    this.extractionSource,
    this.measurementsFound = false,
    this.shippingEstimateSource,
  });

  final String name;
  final double price;
  final String storeName;
  final String country;
  final String? imageUrl;
  final double? weight;
  final String? dimensions;
  /// Canonical URL used for fetch (e.g. Amazon /dp/ASIN).
  final String? canonicalUrl;
  /// Size/color options when API returns them.
  final List<ProductVariation>? variations;

  /// Shipping quote preview from the backend (may be null if insufficient data).
  final ShippingQuotePreview? shippingQuote;

  /// True when the shipping cost is estimated / pending admin review.
  final bool shippingReviewRequired;

  /// Arabic shipping review note from the backend.
  final String? shippingNoteAr;

  /// English shipping review note from the backend.
  final String? shippingNoteEn;

  /// Which extraction pipeline was used (e.g. 'amazon_structured_api', 'jsonld').
  final String? extractionSource;

  /// True when the backend found real weight AND dimensions for this product.
  final bool measurementsFound;

  /// 'exact' when real measurements were used, 'fallback' when defaults were applied.
  final String? shippingEstimateSource;
}

/// Shipping quote preview returned alongside the product import result.
class ShippingQuotePreview {
  const ShippingQuotePreview({
    required this.amount,
    required this.currency,
    required this.estimated,
    this.carrier,
    this.missingFields = const [],
  });

  final double amount;
  final String currency;
  final bool estimated;
  final String? carrier;
  final List<String> missingFields;

  factory ShippingQuotePreview.fromJson(Map<String, dynamic> json) {
    final missing = json['missing_fields'];
    return ShippingQuotePreview(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'USD',
      estimated: json['estimated'] == true,
      carrier: json['carrier'] as String?,
      missingFields: missing is List
          ? missing.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

/// Thrown when the URL is invalid (malformed, not http(s)).
class InvalidLinkException implements Exception {
  InvalidLinkException([this.message = 'Invalid or unsupported link']);
  final String message;
}

/// Thrown when the URL is valid but the store is unsupported (triggers manual entry).
class UnsupportedLinkException implements Exception {
  UnsupportedLinkException([this.message = 'Unsupported store']);
  final String message;
}
