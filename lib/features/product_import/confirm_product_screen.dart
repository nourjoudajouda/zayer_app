import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/add_to_cart_success_sheet.dart';
import '../../generated/l10n/app_localizations.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/cart_providers.dart';
import '../cart/repositories/cart_repository.dart';
import '../paste_link/models/product_import_result.dart';
import '../store_webview/models/detected_product.dart';

/// Confirm Product screen.
/// Shows product details, variations, and shipping estimate before adding to cart.
class ConfirmProductScreen extends ConsumerStatefulWidget {
  const ConfirmProductScreen({
    super.key,
    this.productUrl,
    this.product,
    this.importResult,
  });

  final String? productUrl;
  final DetectedProduct? product;

  /// Optional: full import result from paste-link flow (contains shipping quote).
  final ProductImportResult? importResult;

  @override
  ConsumerState<ConfirmProductScreen> createState() => _ConfirmProductScreenState();
}

class _ConfirmProductScreenState extends ConsumerState<ConfirmProductScreen> {
  int _quantity = 1;
  late final TextEditingController _unitPriceController;
  /// Selected option index per variation (e.g. [0, 1] for first size, second color).
  final Map<int, int> _selectedVariationIndices = {};
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product?.price ?? 0.0;
    _unitPriceController = TextEditingController(
      text: p > 0 ? p.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    super.dispose();
  }

  /// Current unit price from field (for display and add to cart). Falls back to product price.
  double get _unitPrice {
    final parsed = double.tryParse(_unitPriceController.text.trim());
    if (parsed != null && parsed > 0) return parsed;
    return widget.product?.price ?? 0.0;
  }

  String _countryFromStoreKey(String storeKey) {
    switch (storeKey) {
      case 'amazon':
      case 'ebay':
      case 'walmart':
      case 'etsy':
        return 'USA';
      case 'aliexpress':
        return 'China';
      default:
        return 'USA';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use actual product data if available, otherwise use mock data
    final productName = widget.product?.title ?? 'HP 14" Laptop - Intel Core i3 (Mock)';
    final storeName = widget.product?.storeName ?? 'Amazon US';
    final productCurrency = widget.product?.currency ?? 'USD';
    final productImageUrl = widget.product?.imageUrl;
    final usdPrice = _unitPrice;
    final subtotal = usdPrice * _quantity;

    // Shipping data: prefer importResult if available, else treat as pending review.
    final importResult = widget.importResult;
    final shippingQuote = importResult?.shippingQuote;
    final shippingReviewRequired = importResult?.shippingReviewRequired ?? true;
    final hasShippingAmount = shippingQuote != null && shippingQuote.amount > 0;
    final measurementsFound = importResult?.measurementsFound ?? false;
    final shippingEstimateSource = importResult?.shippingEstimateSource;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Confirm Product'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(color: AppConfig.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppConfig.borderColor.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                      child: () {
                        final url = resolveAssetUrl(productImageUrl, ApiClient.safeBaseUrl);
                        return url != null && url.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppConfig.borderColor.withValues(alpha: 0.3),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_outlined,
                                  color: AppConfig.subtitleColor,
                                  size: 40,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.image_outlined,
                              color: AppConfig.subtitleColor,
                              size: 40,
                            );
                      }(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            storeName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppConfig.subtitleColor,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'USD ${usdPrice.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppConfig.primaryColor,
                                    ),
                              ),
                              if (productCurrency != 'USD') ...[
                                const SizedBox(width: 8),
                                Text(
                                  '($productCurrency)',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppConfig.subtitleColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                    const SizedBox(height: AppSpacing.lg),
              // Variations (size / color) when available
              if (widget.product?.variations != null &&
                  widget.product!.variations!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                    border: Border.all(color: AppConfig.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Options',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...List.generate(widget.product!.variations!.length, (i) {
                        final v = widget.product!.variations![i];
                        final selectedIndex = _selectedVariationIndices[i] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  v.displayLabel,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppConfig.subtitleColor,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedIndex.clamp(0, v.options.length - 1),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: List.generate(v.options.length, (j) {
                                    final opt = v.options[j];
                                    final price = v.priceAt(j);
                                    final label = price != null
                                        ? '$opt — \$${price.toStringAsFixed(2)}'
                                        : opt;
                                    return DropdownMenuItem(value: j, child: Text(label));
                                  }),
                                  onChanged: (int? newIndex) {
                                    if (newIndex == null) return;
                                    setState(() {
                                      _selectedVariationIndices[i] = newIndex;
                                      final price = v.priceAt(newIndex);
                                      if (price != null && price > 0) {
                                        _unitPriceController.text = price.toStringAsFixed(2);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              // Unit price (user can set exact price when there are multiple variations)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit price (USD)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'If this product has multiple options (e.g. size or color), enter the price for your selection.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: widget.product != null,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Quantity
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () => setState(
                              () => _quantity = math.max(1, _quantity - 1)),
                          icon: const Icon(Icons.remove, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppConfig.borderColor,
                            foregroundColor: AppConfig.textColor,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_quantity',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Cost breakdown
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cost Breakdown',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCostRow(
                      'Product × $_quantity',
                      'USD ${subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCostRow(
                      shippingEstimateSource == 'exact'
                          ? 'Shipping (exact)'
                          : 'Shipping (estimated)',
                      hasShippingAmount
                          ? '≈ ${shippingQuote.currency} ${shippingQuote.amount.toStringAsFixed(2)}'
                          : 'Pending Review',
                      isEstimated: hasShippingAmount && shippingReviewRequired,
                      isFallback: !measurementsFound,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildCostRow(
                      'Total',
                      hasShippingAmount
                          ? 'USD ${(subtotal + shippingQuote.amount).toStringAsFixed(2)}'
                          : 'Pending Review',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              // Shipping review banner — shown when shipping is estimated/pending
              if (shippingReviewRequired) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (!measurementsFound
                              ? 'Shipping is estimated using default dimensions. '
                              : '') +
                          (l10n?.shippingReviewNoteFull ??
                              'The shipping cost shown is an estimate only and will be reviewed and confirmed by admin.'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.textColor,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildCostRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isEstimated = false,
    bool isFallback = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? AppConfig.textColor : AppConfig.subtitleColor,
              ),
        ),
        Row(
          children: [
            if (isEstimated || isFallback)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isFallback ? Icons.straighten_outlined : Icons.info_outline,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
              ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                    color: (isEstimated || isFallback)
                        ? Colors.orange.shade800
                        : (isTotal ? AppConfig.primaryColor : AppConfig.textColor),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addToCart() async {
    final product = widget.product;
    final productUrl = widget.productUrl ?? product?.productUrl ?? '';
    final unitPrice = _unitPrice;

    if (productUrl.isEmpty || product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing product information'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }
    if (unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid unit price'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }

    final country = _countryFromStoreKey(product.storeKey);
    String? variationText;
    if (product.variations != null && product.variations!.isNotEmpty) {
      variationText = product.variations!
          .asMap()
          .entries
          .map((e) {
            final idx = _selectedVariationIndices[e.key] ?? 0;
            final opt = e.value.options.length > idx ? e.value.options[idx] : '';
            return '${e.value.displayLabel}: $opt';
          })
          .join(', ');
    }
    final cartItem = CartItem(
      id: generateCartItemId(),
      productUrl: productUrl,
      name: product.title ?? 'Product',
      unitPrice: unitPrice,
      quantity: _quantity,
      currency: product.currency,
      imageUrl: product.imageUrl,
      storeKey: product.storeKey,
      storeName: product.storeName,
      productId: product.productId,
      country: country,
      source: 'webview',
      variationText: variationText,
    );

    if (!mounted) return;
    setState(() => _isAddingToCart = true);
    try {
      final cartNotifier = ref.read(cartItemsProvider.notifier);
      final added = await cartNotifier.addItem(cartItem);

      if (mounted) {
        if (added) {
          final choice = await showAddToCartSuccessSheet(
            context,
            message: 'Do you want to continue shopping or go to your cart?',
          );
          if (!mounted) return;
          if (choice == AddToCartSuccessAction.goToCart) {
            Navigator.of(context).popUntil((route) {
              return route.isFirst ||
                  route.settings.name == AppRoutes.storeLanding ||
                  route.settings.name == AppRoutes.home;
            });
            if (context.mounted) context.go(AppRoutes.cart);
          } else {
            // Continue shopping: pop confirm screen only, stay in store webview
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This item is already in your cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    final loading = _isAddingToCart;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
          onPressed: loading ? null : _addToCart,
          icon: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline, size: 22),
          label: Text(loading ? 'Adding...' : 'Confirm & Add to Cart'),
          style: FilledButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}
