import '../../product_import/models/product_variation.dart';

/// Detected product model for WebView import.
class DetectedProduct {
  const DetectedProduct({
    required this.storeKey,
    required this.storeName,
    required this.productUrl,
    this.title,
    this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.productId,
    this.variations,
  });

  final String storeKey;
  final String storeName;
  final String productUrl;
  final String? title;
  final double? price;
  final String currency;
  final String? imageUrl;
  final String? productId;
  /// e.g. size and color options; when present, user selects on confirm screen.
  final List<ProductVariation>? variations;

  /// Mock factory for Amazon products.
  factory DetectedProduct.mockAmazon(String url, {String? asin}) {
    return DetectedProduct(
      storeKey: 'amazon',
      storeName: 'Amazon US',
      productUrl: url,
      title: 'HP 14" Laptop - Intel Core i3 (Mock)',
      price: 499.99,
      currency: 'USD',
      imageUrl: null,
      productId: asin,
    );
  }

  /// Mock factory for eBay products.
  factory DetectedProduct.mockEbay(String url) {
    return DetectedProduct(
      storeKey: 'ebay',
      storeName: 'eBay US',
      productUrl: url,
      title: 'Vintage Watch (Mock)',
      price: 89.00,
      currency: 'USD',
      imageUrl: null,
    );
  }

  /// Mock factory for Walmart products.
  factory DetectedProduct.mockWalmart(String url, {String? productId}) {
    return DetectedProduct(
      storeKey: 'walmart',
      storeName: 'Walmart US',
      productUrl: url,
      title: 'Product (Mock)',
      price: 29.99,
      currency: 'USD',
      imageUrl: null,
      productId: productId,
    );
  }

  /// Mock factory for Etsy products.
  factory DetectedProduct.mockEtsy(String url, {String? listingId}) {
    return DetectedProduct(
      storeKey: 'etsy',
      storeName: 'Etsy',
      productUrl: url,
      title: 'Handmade Item (Mock)',
      price: 45.00,
      currency: 'USD',
      imageUrl: null,
      productId: listingId,
    );
  }

  /// Mock factory for AliExpress products.
  factory DetectedProduct.mockAliExpress(String url, {String? itemId}) {
    return DetectedProduct(
      storeKey: 'aliexpress',
      storeName: 'AliExpress',
      productUrl: url,
      title: 'Product (Mock)',
      price: 15.99,
      currency: 'USD',
      imageUrl: null,
      productId: itemId,
    );
  }
}
