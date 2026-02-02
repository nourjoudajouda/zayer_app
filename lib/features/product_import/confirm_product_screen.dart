import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';

/// Confirm Product screen (MVP mock).
/// Shows product details and mock shipping/duties before adding to cart.
class ConfirmProductScreen extends StatefulWidget {
  const ConfirmProductScreen({super.key, this.productUrl});

  final String? productUrl;

  @override
  State<ConfirmProductScreen> createState() => _ConfirmProductScreenState();
}

class _ConfirmProductScreenState extends State<ConfirmProductScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    // Mock product data
    const productName = 'HP 14" Laptop - Intel Core i3 (Mock)';
    const storeName = 'Amazon US';
    const storePrice = 499.99;
    const estimatedShipping = 45.0;
    const estimatedDuties = 60.0;
    final total = (storePrice * _quantity) + estimatedShipping + estimatedDuties;

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
                      child: const Icon(
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
                          Text(
                            'USD ${storePrice.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.primaryColor,
                                ),
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
                      'USD ${(storePrice * _quantity).toStringAsFixed(2)}',
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

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to cart (mock)'),
              ),
            );
          },
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
