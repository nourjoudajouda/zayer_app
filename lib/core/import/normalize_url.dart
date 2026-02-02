/// Result of URL normalization/canonicalization.
/// Used before PDP detection and import.
class NormalizedUrlResult {
  const NormalizedUrlResult({
    required this.canonicalUrl,
    required this.storeKey,
    this.productId,
    this.wasModified = false,
  });

  /// Canonical URL to use for fetching (e.g. https://www.amazon.com/dp/ASIN).
  final String canonicalUrl;

  /// Store identifier: "amazon", "ebay", or "unknown".
  final String storeKey;

  /// Product ID when extractable (e.g. ASIN for Amazon, item id for eBay).
  final String? productId;

  /// True if the URL was modified (e.g. scheme added, Amazon canonicalized).
  final bool wasModified;
}

/// Normalizes a product URL for import. Amazon must normalize to /dp/{ASIN}.
NormalizedUrlResult normalizeProductUrl(String input) {
  String url = input.trim();
  if (url.isEmpty) {
    return NormalizedUrlResult(
      canonicalUrl: '',
      storeKey: 'unknown',
      wasModified: false,
    );
  }

  // Ensure http(s) scheme.
  bool wasModified = false;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
    wasModified = true;
  }

  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return NormalizedUrlResult(
      canonicalUrl: url,
      storeKey: 'unknown',
      wasModified: wasModified,
    );
  }

  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return NormalizedUrlResult(
      canonicalUrl: url,
      storeKey: 'unknown',
      wasModified: wasModified,
    );
  }

  final host = uri.host.toLowerCase();

  // Amazon: extract ASIN, canonicalize to /dp/{ASIN}
  if (host.contains('amazon.')) {
    final asin = _extractAmazonAsin(uri);
    if (asin != null && asin.isNotEmpty) {
      final canonical = 'https://www.amazon.com/dp/$asin';
      return NormalizedUrlResult(
        canonicalUrl: canonical,
        storeKey: 'amazon',
        productId: asin,
        wasModified: wasModified || url != canonical,
      );
    }
    // Still Amazon but no ASIN found - use as-is
    return NormalizedUrlResult(
      canonicalUrl: url,
      storeKey: 'amazon',
      wasModified: wasModified,
    );
  }

  // eBay: extract item id if possible
  if (host.contains('ebay.')) {
    final itemId = _extractEbayItemId(uri);
    return NormalizedUrlResult(
      canonicalUrl: url,
      storeKey: 'ebay',
      productId: itemId,
      wasModified: wasModified,
    );
  }

  return NormalizedUrlResult(
    canonicalUrl: url,
    storeKey: 'unknown',
    wasModified: wasModified,
  );
}

/// Extract Amazon ASIN from path or query.
/// Patterns: /dp/{ASIN}, /gp/product/{ASIN}, /product/{ASIN}
String? _extractAmazonAsin(Uri uri) {
  // ASIN is 10 alphanumeric chars (B0xxxxxxxx or 0xxxxxxxxx).
  final asinPattern = RegExp(r'[A-Z0-9]{10}');

  // /dp/{ASIN} or /gp/product/{ASIN} or /product/{ASIN}
  final pathSegments = uri.pathSegments;
  for (int i = 0; i < pathSegments.length; i++) {
    final seg = pathSegments[i].toLowerCase();
    if ((seg == 'dp' || seg == 'product') && i + 1 < pathSegments.length) {
      final candidate = pathSegments[i + 1];
      if (asinPattern.hasMatch(candidate) && candidate.length == 10) {
        return candidate;
      }
    }
    if (seg == 'gp' && i + 2 < pathSegments.length && pathSegments[i + 1].toLowerCase() == 'product') {
      final candidate = pathSegments[i + 2];
      if (asinPattern.hasMatch(candidate) && candidate.length == 10) {
        return candidate;
      }
    }
  }

  // Query: asin=...
  final asinQuery = uri.queryParameters['asin'];
  if (asinQuery != null && asinQuery.length == 10 && asinPattern.hasMatch(asinQuery)) {
    return asinQuery;
  }

  return null;
}

/// Extract eBay item ID from path /itm/{id} or query item=...
String? _extractEbayItemId(Uri uri) {
  final pathSegments = uri.pathSegments;
  for (int i = 0; i < pathSegments.length; i++) {
    if (pathSegments[i].toLowerCase() == 'itm' && i + 1 < pathSegments.length) {
      return pathSegments[i + 1];
    }
  }
  return uri.queryParameters['item'];
}
