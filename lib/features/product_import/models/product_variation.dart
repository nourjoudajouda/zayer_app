/// One variation dimension (e.g. Size or Color) with options.
class ProductVariation {
  const ProductVariation({
    required this.type,
    required this.options,
    this.prices,
  });

  /// e.g. 'size', 'color'
  final String type;

  /// e.g. ['S', 'M', 'L'] or ['Red', 'Blue']
  final List<String> options;

  /// Optional price per option (same order as [options]). If null, use product base price.
  final List<double>? prices;

  String get displayLabel {
    switch (type.toLowerCase()) {
      case 'size':
        return 'Size';
      case 'color':
        return 'Color';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : type;
    }
  }

  double? priceAt(int index) {
    if (prices == null || index < 0 || index >= prices!.length) return null;
    return prices![index];
  }

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    final opts = json['options'];
    final list = opts is List ? opts.map((e) => e.toString()).toList() : <String>[];
    final p = json['prices'];
    List<double>? prices;
    if (p is List) {
      prices = p.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0).toList();
    }
    return ProductVariation(
      type: (json['type'] ?? json['label'] ?? '').toString(),
      options: list,
      prices: prices,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'options': options,
        if (prices != null) 'prices': prices,
      };
}
