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
