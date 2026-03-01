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
}

enum FavoriteStockStatus {
  inStock,
  lowStock,
  outOfStock,
}
