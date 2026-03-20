/// Admin review status: item cannot ship until reviewed (dangerous/fragile check).
enum CartItemReviewStatus {
  pendingReview,
  reviewed,
  rejected,
}

/// Unified cart item for both WebView import and Paste Link flows.
/// Stored locally and sent to backend via POST /api/cart/items.
class CartItem {
  const CartItem({
    required this.id,
    required this.productUrl,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.currency = 'USD',
    this.imageUrl,
    this.storeKey,
    this.storeName,
    this.productId,
    this.country,
    this.weight,
    this.weightUnit,
    this.length,
    this.width,
    this.height,
    this.dimensionUnit,
    required this.source,
    this.syncedToBackend = false,
    this.reviewStatus = CartItemReviewStatus.pendingReview,
    this.shippingCost,
    this.shippingEstimated = false,
    this.variationText,
    this.destinationAddressId,
  });

  /// e.g. "Size: M, Color: Red" for display when product has variations.
  final String? variationText;

  /// Local unique id (e.g. uuid).
  final String id;
  final String productUrl;
  final String name;
  final double unitPrice;
  final int quantity;
  final String currency;
  final String? imageUrl;
  final String? storeKey;
  final String? storeName;
  final String? productId;
  /// Country of origin for grouping (e.g. USA, Turkey).
  final String? country;
  final double? weight;
  final String? weightUnit; // 'lb' | 'g'
  final double? length;
  final double? width;
  final double? height;
  final String? dimensionUnit; // 'in' | 'cm'
  /// 'webview' = from product page, 'paste_link' = from Add via Link.
  final String source;
  final bool syncedToBackend;
  /// Admin must review before item can ship (dangerous/fragile).
  final CartItemReviewStatus reviewStatus;
  /// Shipping cost for this item (or per-unit). Filled by backend/checkout.
  final double? shippingCost;

  /// True when quote used fallbacks or incomplete product data (API `estimated`).
  final bool shippingEstimated;

  /// Saved address id used for shipping quote (POST `destination_address_id`). From API `shipping_destination.address_id`.
  final String? destinationAddressId;

  double get totalPrice => unitPrice * quantity;
  double get totalShipping => (shippingCost ?? 0) * quantity;
  bool get isReviewed => reviewStatus == CartItemReviewStatus.reviewed;

  CartItem copyWith({
    String? id,
    String? productUrl,
    String? name,
    double? unitPrice,
    int? quantity,
    String? currency,
    String? imageUrl,
    String? storeKey,
    String? storeName,
    String? productId,
    String? country,
    double? weight,
    String? weightUnit,
    double? length,
    double? width,
    double? height,
    String? dimensionUnit,
    String? source,
    bool? syncedToBackend,
    CartItemReviewStatus? reviewStatus,
    double? shippingCost,
    bool? shippingEstimated,
    String? variationText,
    String? destinationAddressId,
  }) {
    return CartItem(
      id: id ?? this.id,
      productUrl: productUrl ?? this.productUrl,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      storeKey: storeKey ?? this.storeKey,
      storeName: storeName ?? this.storeName,
      productId: productId ?? this.productId,
      country: country ?? this.country,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      source: source ?? this.source,
      syncedToBackend: syncedToBackend ?? this.syncedToBackend,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      shippingCost: shippingCost ?? this.shippingCost,
      shippingEstimated: shippingEstimated ?? this.shippingEstimated,
      variationText: variationText ?? this.variationText,
      destinationAddressId: destinationAddressId ?? this.destinationAddressId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': productUrl,
      'canonical_url': productUrl,
      'name': name,
      'price': unitPrice,
      'quantity': quantity,
      'currency': currency,
      'image_url': imageUrl,
      'store_key': storeKey,
      'store_name': storeName,
      'product_id': productId,
      'country': country,
      'weight': weight,
      'weight_unit': weightUnit,
      'length': length,
      'width': width,
      'height': height,
      'dimension_unit': dimensionUnit,
      'source': source,
      'review_status': reviewStatus.name,
      'shipping_cost': shippingCost,
      'estimated': shippingEstimated,
      'variation_text': variationText,
      if (destinationAddressId != null) 'destination_address_id': destinationAddressId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    CartItemReviewStatus status = CartItemReviewStatus.pendingReview;
    final s = json['review_status'] as String?;
    if (s == 'reviewed') status = CartItemReviewStatus.reviewed;
    if (s == 'rejected') status = CartItemReviewStatus.rejected;
    String? destAddrId;
    final sd = json['shipping_destination'];
    if (sd is Map<String, dynamic>) {
      final raw = sd['address_id'];
      if (raw != null) destAddrId = raw.toString();
    }
    destAddrId ??= json['destination_address_id']?.toString();

    return CartItem(
      id: json['id'] as String,
      productUrl: json['url'] as String? ?? json['product_url'] as String? ?? json['productUrl'] as String? ?? '',
      name: json['name'] as String,
      unitPrice: (json['price'] as num?)?.toDouble() ?? (json['unit_price'] as num?)?.toDouble() ?? (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      storeKey: json['store_key'] as String? ?? json['storeKey'] as String?,
      storeName: json['store_name'] as String? ?? json['storeName'] as String?,
      productId: json['product_id'] as String? ?? json['productId'] as String?,
      country: json['country'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String? ?? json['weightUnit'] as String?,
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      dimensionUnit: json['dimension_unit'] as String? ?? json['dimensionUnit'] as String?,
      source: json['source'] as String? ?? 'paste_link',
      syncedToBackend: json['syncedToBackend'] as bool? ?? false,
      reviewStatus: status,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble(),
      shippingEstimated: json['estimated'] == true,
      variationText: json['variation_text'] as String? ?? json['variationText'] as String?,
      destinationAddressId: destAddrId,
    );
  }
}
