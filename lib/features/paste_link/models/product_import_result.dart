import '../../product_import/models/product_variation.dart';

/// Result of fetching product metadata from a URL.
class ProductImportResult {
  const ProductImportResult({
    required this.name,
    required this.price,
    this.storeKey,
    required this.storeName,
    required this.country,
    this.imageUrl,
    this.weight,
    this.dimensions,
    this.dimensionsData,
    this.canonicalUrl,
    this.variations,
    this.shippingQuote,
    this.shippingEstimate,
    this.shippingReviewRequired = true,
    this.shippingNoteAr,
    this.shippingNoteEn,
    this.extractionSource,
    this.measurementsFound = false,
    this.shippingEstimateSource,
    this.weightUnit,
    this.appFeePercent = 0,
    this.appFeeAmount = 0,
    this.payableNowTotal = 0,
    this.shippingPayableNow = 0,
    /// Backend: `standard` = normal import/cart path; `purchase_assistant` = manual team pricing.
    this.importFlow = 'standard',
  });

  final String name;
  final double price;
  /// Normalized store key from backend (e.g. 'amazon', 'ebay').
  final String? storeKey;
  final String storeName;
  final String country;
  final String? imageUrl;
  final double? weight;
  /// e.g. lb, kg — from API when present.
  final String? weightUnit;
  /// Dimensions as a formatted string for UI (backwards compatible).
  final String? dimensions;
  /// Structured dimensions from backend (if provided).
  final ProductDimensions? dimensionsData;
  /// Canonical URL used for fetch (e.g. Amazon /dp/ASIN).
  final String? canonicalUrl;
  /// Size/color options when API returns them.
  final List<ProductVariation>? variations;

  /// Shipping quote preview from the backend (may be null if insufficient data).
  final ShippingQuotePreview? shippingQuote;

  /// Required normalized estimate block.
  final ShippingEstimate? shippingEstimate;

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

  /// Admin-configured app fee percent (product subtotal only; not shipping).
  final double appFeePercent;

  /// Fee amount for current line subtotal from import API (informational; recalc if user edits price).
  final double appFeeAmount;

  /// Product subtotal + app fee at import time (shipping not included).
  final double payableNowTotal;

  /// Always 0 at this stage — shipping is not charged with product yet.
  final int shippingPayableNow;

  /// `standard` or `purchase_assistant` (from API `import_flow`).
  final String importFlow;
}

class ProductDimensions {
  const ProductDimensions({
    this.length,
    this.width,
    this.height,
    required this.unit,
  });

  final double? length;
  final double? width;
  final double? height;
  final String unit; // 'cm' | 'in' | 'mm' etc.

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    double? p(String k) {
      final v = json[k];
      if (v is num) return v.toDouble();
      return null;
    }

    return ProductDimensions(
      length: p('length'),
      width: p('width'),
      height: p('height'),
      unit: (json['unit'] as String?) ?? (json['dimension_unit'] as String?) ?? 'cm',
    );
  }

  /// All three dimensions present and positive (e.g. volumetric box complete).
  bool get isValid =>
      (length ?? 0) > 0 && (width ?? 0) > 0 && (height ?? 0) > 0;

  /// At least one positive dimension (partial extraction, e.g. height-only).
  bool get hasAnyDimension =>
      (length ?? 0) > 0 || (width ?? 0) > 0 || (height ?? 0) > 0;

  String format() {
    final parts = <String>[];
    if ((length ?? 0) > 0) parts.add('L=$length');
    if ((width ?? 0) > 0) parts.add('W=$width');
    if ((height ?? 0) > 0) parts.add('H=$height');
    if (parts.isEmpty) return '';
    return '${parts.join(' × ')} $unit';
  }
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

class ShippingEstimate {
  const ShippingEstimate({
    required this.amount,
    required this.source,
    required this.note,
  });

  final double? amount;
  /// 'exact' | 'fallback'
  final String source;
  /// always "approximate"
  final String note;

  factory ShippingEstimate.fromJson(Map<String, dynamic> json) {
    final a = json['amount'];
    return ShippingEstimate(
      amount: a is num ? a.toDouble() : null,
      source: (json['source'] as String?) ?? 'fallback',
      note: (json['note'] as String?) ?? 'approximate',
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
