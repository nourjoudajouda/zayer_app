import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/cart_providers.dart';
import '../cart/repositories/cart_repository.dart';
import '../store_webview/models/detected_product.dart';

/// Confirm Product screen (MVP mock).
/// Shows product details and mock shipping/duties before adding to cart.
class ConfirmProductScreen extends ConsumerStatefulWidget {
  const ConfirmProductScreen({
    super.key,
    this.productUrl,
    this.product,
  });

  final String? productUrl;
  final DetectedProduct? product;

  @override
  ConsumerState<ConfirmProductScreen> createState() => _ConfirmProductScreenState();
}

class _ConfirmProductScreenState extends ConsumerState<ConfirmProductScreen> {
  int _quantity = 1;

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

  /// Convert price from any currency to USD using estimated rates
  /// In production, use real-time exchange rates from API
  double _convertToUSD(double price, String currency) {
    // Estimated exchange rates (should be fetched from API in production)
    const exchangeRates = {
      'USD': 1.0,
      'EUR': 1.08,
      'GBP': 1.27,
      'AED': 0.27,
      'SAR': 0.27,
      'EGP': 0.032,
      'ILS': 0.27, // Israeli Shekel: 1 ILS ≈ 0.27 USD
      'NIS': 0.27, // New Israeli Shekel (same as ILS)
      '₪': 0.27, // Shekel symbol
    };
    
    final rate = exchangeRates[currency.toUpperCase()] ?? exchangeRates[currency] ?? 1.0;
    return price * rate;
  }

  @override
  Widget build(BuildContext context) {
    // Use actual product data if available, otherwise use mock data
    final productName = widget.product?.title ?? 'HP 14" Laptop - Intel Core i3 (Mock)';
    final storeName = widget.product?.storeName ?? 'Amazon US';
    final storePrice = widget.product?.price ?? 499.99;
    final productCurrency = widget.product?.currency ?? 'USD';
    final productImageUrl = widget.product?.imageUrl;
    
    // Convert all prices to USD for calculation (estimated rates)
    // In production, use real-time exchange rates from API
    final usdPrice = _convertToUSD(storePrice, productCurrency);
    const estimatedShipping = 45.0; // Always in USD
    const estimatedDuties = 60.0; // Always in USD
    final total = (usdPrice * _quantity) + estimatedShipping + estimatedDuties;
    
    // Show warning if currency is not USD
    final showCurrencyWarning = productCurrency != 'USD';

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
                      child: productImageUrl != null && productImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                              child: CachedNetworkImage(
                                imageUrl: productImageUrl,
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
                            ),
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
                                '$productCurrency ${storePrice.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppConfig.primaryColor,
                                    ),
                              ),
                              if (showCurrencyWarning) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(≈ USD ${usdPrice.toStringAsFixed(2)})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
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
                      'Cost Breakdown (Estimated)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCostRow(
                      'Product × $_quantity',
                      showCurrencyWarning
                          ? '$productCurrency ${(storePrice * _quantity).toStringAsFixed(2)} (≈ USD ${(usdPrice * _quantity).toStringAsFixed(2)})'
                          : 'USD ${(usdPrice * _quantity).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCostRow(
                      'International Shipping',
                      'USD ${estimatedShipping.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCostRow(
                      'Import Duties & Taxes',
                      'USD ${estimatedDuties.toStringAsFixed(2)}',
                    ),
                    if (showCurrencyWarning) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppConfig.primaryColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Prices converted to USD using estimated rates',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppConfig.primaryColor,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: AppSpacing.lg),
                    _buildCostRow(
                      'Estimated Total',
                      'USD ${total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Final costs will be calculated after review and shared for your approval before purchase.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
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
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? AppConfig.primaryColor : AppConfig.textColor,
              ),
        ),
      ],
    );
  }

  Future<void> _addToCart() async {
    final product = widget.product;
    final productUrl = widget.productUrl ?? product?.productUrl ?? '';
    
    if (productUrl.isEmpty || product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing product information'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }

    final country = _countryFromStoreKey(product.storeKey);
    final cartItem = CartItem(
      id: generateCartItemId(),
      productUrl: productUrl,
      name: product.title ?? 'Product',
      unitPrice: product.price ?? 0.0,
      quantity: _quantity,
      currency: product.currency,
      imageUrl: product.imageUrl,
      storeKey: product.storeKey,
      storeName: product.storeName,
      productId: product.productId,
      country: country,
      source: 'webview',
    );

    final cartNotifier = ref.read(cartItemsProvider.notifier);
    await cartNotifier.addItem(cartItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
      
      // Pop confirm screen and store webview to return to store landing
      Navigator.of(context).popUntil((route) {
        // Pop until we reach the store landing or home screen
        return route.isFirst || 
               route.settings.name == AppRoutes.storeLanding ||
               route.settings.name == AppRoutes.home;
      });
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
          onPressed: _addToCart,
          icon: const Icon(Icons.check_circle_outline, size: 22),
          label: const Text('Confirm & Add to Cart'),
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
