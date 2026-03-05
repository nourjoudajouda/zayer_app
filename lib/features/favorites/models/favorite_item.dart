/// A favorited product with price tracking and availability.
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.sourceKey,
    required this.sourceLabel,
    required this.title,
    required this.price,
    required this.currency,
    this.priceDrop,
    required this.trackingOn,
    required this.stockStatus,
    required this.stockLabel,
    this.imageUrl,
  });

  final String id;
  final String sourceKey; // 'amazon', 'shein', etc.
  final String sourceLabel; // 'FOUND ON AMAZON'
  final String title;
  final double price;
  final String currency;
  final double? priceDrop; // e.g. 12 for "↘ €12"
  final bool trackingOn;
  final FavoriteStockStatus stockStatus;
  final String stockLabel; // 'In Stock', 'Low Stock (2 left)', 'OUT OF STOCK'
  final String? imageUrl;

  bool get isOutOfStock => stockStatus == FavoriteStockStatus.outOfStock;

  String get priceFormatted => '$currency${price.toStringAsFixed(2)}';

  factory FavoriteItem.fromJson(Map<String, dynamic> j) {
    FavoriteStockStatus status = FavoriteStockStatus.inStock;
    final s = j['stock_status'] as String?;
    if (s == 'low_stock') status = FavoriteStockStatus.lowStock;
    if (s == 'out_of_stock') status = FavoriteStockStatus.outOfStock;
    return FavoriteItem(
      id: (j['id'] ?? '').toString(),
      sourceKey: (j['source_key'] ?? '').toString(),
      sourceLabel: (j['source_label'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      price: (j['price'] as num?)?.toDouble() ?? 0,
      currency: (j['currency'] ?? 'USD').toString(),
      priceDrop: (j['price_drop'] as num?)?.toDouble(),
      trackingOn: j['tracking_on'] != false,
      stockStatus: status,
      stockLabel: (j['stock_label'] ?? 'In Stock').toString(),
      imageUrl: j['image_url'] as String?,
    );
  }
}

enum FavoriteStockStatus {
  inStock,
  lowStock,
  outOfStock,
}
