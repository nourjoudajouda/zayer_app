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
    final p = widget.importResult?.price ?? widget.product?.price ?? 0.0;
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
    final importResult = widget.importResult;
    final productName = importResult?.name ?? widget.product?.title ?? 'Product';
    final storeName = importResult?.storeName ?? widget.product?.storeName ?? '';
    final productCurrency = widget.product?.currency ?? 'USD';
    final productImageUrl = importResult?.imageUrl ?? widget.product?.imageUrl;
    final usdPrice = _unitPrice;
    final subtotal = usdPrice * _quantity;
    final variations = importResult?.variations ?? widget.product?.variations;

    // Shipping data: prefer normalized shipping_estimate if available; fall back to shipping_quote.amount.
    final shippingQuote = importResult?.shippingQuote;
    final shippingEstimate = importResult?.shippingEstimate;
    final double? shippingAmount = () {
      final a = shippingEstimate?.amount;
      if (a != null && a > 0) return a;
      final q = shippingQuote?.amount;
      if (q != null && q > 0) return q;
      return null;
    }();
    final hasShippingAmount = shippingAmount != null && shippingAmount > 0;
    final shippingAmountValue = shippingAmount ?? 0.0;
    final measurementsFound = importResult?.measurementsFound ?? false;
    final String? shippingEstimateSource =
        importResult?.shippingEstimateSource ?? shippingEstimate?.source;
    final isExactShipping = shippingEstimateSource == 'exact';
    /// Any non-exact source (fallback, unknown, null) uses estimated labeling when an amount exists.
    final isFallbackShipping = !isExactShipping;
    final hasAnyMeasurement = (importResult?.weight != null && (importResult!.weight ?? 0) > 0) ||
        (importResult?.dimensionsData?.isValid == true) ||
        ((importResult?.dimensions ?? '').trim().isNotEmpty);

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
              if (variations != null && variations.isNotEmpty) ...[
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
                      ...List.generate(variations.length, (i) {
                        final v = variations[i];
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
                      isExactShipping ? 'Shipping (exact)' : 'Shipping (estimated)',
                      hasShippingAmount
                          ? '≈ ${(shippingQuote?.currency ?? 'USD')} ${shippingAmountValue.toStringAsFixed(2)}'
                          : 'Pending Review',
                      isEstimated: hasShippingAmount && !isExactShipping,
                      isFallback: hasShippingAmount && isFallbackShipping,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildCostRow(
                      'Total',
                      hasShippingAmount
                          ? 'USD ${(subtotal + shippingAmountValue).toStringAsFixed(2)}'
                          : 'Pending Review',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              // Approximate-shipping disclaimer when backend used fallback defaults but returned an amount.
              if (hasShippingAmount && isFallbackShipping) ...[
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
                          (isFallbackShipping
                                  ? (l10n?.shippingFallbackPrefix ??
                                      'Estimated shipping based on fallback measurements. ')
                                  : '') +
                              (l10n?.shippingReviewNoteFull ??
                                  'The shipping cost shown is an estimate only and will be reviewed and confirmed by admin after inspecting the product and its specifications.'),
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
              const SizedBox(height: AppSpacing.sm),
              // Measurements: show only what is actually present (no fake values)
              if (hasAnyMeasurement) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    border: Border.all(color: AppConfig.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Measurements',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (importResult?.weight != null && (importResult!.weight ?? 0) > 0)
                        Text('${l10n?.weightLabel ?? 'Weight'}: ${importResult.weight}'),
                      if (importResult?.dimensionsData?.isValid == true)
                        Text('${l10n?.dimensionsLabel ?? 'Dimensions'}: ${importResult!.dimensionsData!.format()}'),
                      if (importResult?.dimensionsData?.isValid != true &&
                          importResult?.dimensions != null &&
                          importResult!.dimensions!.trim().isNotEmpty)
                        Text('${l10n?.dimensionsLabel ?? 'Dimensions'}: ${importResult.dimensions}'),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isExactShipping
                                ? AppConfig.successGreen.withValues(alpha: 0.10)
                                : Colors.orange.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                            border: Border.all(
                              color: isExactShipping
                                  ? AppConfig.successGreen.withValues(alpha: 0.25)
                                  : Colors.orange.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            isExactShipping
                                ? (l10n?.exactMeasurementsLabel ?? 'Exact measurements')
                                : (l10n?.estimatedShippingLabel ?? 'Estimated shipping'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isExactShipping
                                      ? AppConfig.successGreen
                                      : Colors.orange.shade800,
                                ),
                          ),
                        ),
                      ),
                      if (!measurementsFound) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n?.measurementsNotAvailable ??
                              'Measurements not available from store. Shipping is estimated and subject to review.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.subtitleColor,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (hasShippingAmount && isFallbackShipping) ...[
                // Fallback shipping used — do not show fake measurements
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    l10n?.measurementsNotAvailable ??
                        'Measurements not available from store. Shipping is estimated and subject to review.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConfig.textColor,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
              if (shippingEstimate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n?.shippingNoteLabel ?? 'Shipping note'}: ${shippingEstimate.note}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
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
    final importResult = widget.importResult;
    final product = widget.product;
    final productUrl = importResult?.canonicalUrl ?? widget.productUrl ?? product?.productUrl ?? '';
    final unitPrice = _unitPrice;

    if (productUrl.isEmpty || (product == null && importResult == null)) {
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

    final storeKey = importResult?.storeKey ?? product?.storeKey;
    final storeName = importResult?.storeName ?? product?.storeName;
    final country = importResult?.country ??
        (storeKey != null ? _countryFromStoreKey(storeKey) : (product?.storeKey != null ? _countryFromStoreKey(product!.storeKey) : 'USA'));
    String? variationText;
    final variations = importResult?.variations ?? product?.variations;
    if (variations != null && variations.isNotEmpty) {
      variationText = variations
          .asMap()
          .entries
          .map((e) {
            final idx = _selectedVariationIndices[e.key] ?? 0;
            final opt = e.value.options.length > idx ? e.value.options[idx] : '';
            return '${e.value.displayLabel}: $opt';
          })
          .join(', ');
    }
    final dims = importResult?.dimensionsData;
    final cartItem = CartItem(
      id: generateCartItemId(),
      productUrl: productUrl,
      name: importResult?.name ?? product?.title ?? 'Product',
      unitPrice: unitPrice,
      quantity: _quantity,
      currency: 'USD',
      imageUrl: importResult?.imageUrl ?? product?.imageUrl,
      storeKey: storeKey,
      storeName: storeName,
      productId: product?.productId,
      country: country,
      source: product != null ? 'webview' : 'paste_link',
      variationText: variationText,
      weight: importResult?.weight,
      weightUnit: importResult?.weightUnit,
      length: dims?.length,
      width: dims?.width,
      height: dims?.height,
      dimensionUnit: dims?.unit,
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
