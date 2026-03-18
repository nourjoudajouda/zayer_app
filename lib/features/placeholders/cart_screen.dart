import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../cart/cart_empty_screen.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/cart_providers.dart';
import '../profile/providers/profile_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  /// Group items by country for display (USA Shipment, Turkey Shipment, etc.)
  static Map<String, List<CartItem>> _groupByCountry(List<CartItem> items) {
    final map = <String, List<CartItem>>{};
    for (final item in items) {
      final country = item.country ?? 'Other';
      map.putIfAbsent(country, () => []).add(item);
    }
    return map;
  }

  static List<Widget> _buildGroupedSections(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> cartItems,
    CartNotifier cartNotifier,
    String? loadingItemId,
  ) {
    final byCountry = _groupByCountry(cartItems);
    final widgets = <Widget>[];
    for (final entry in byCountry.entries) {
      final countryLabel = '${entry.key} Shipment';
      final items = entry.value;
      final allReviewed = items.every((i) => i.isReviewed);
      final hasAllShippingCosts = items.every((i) => i.shippingCost != null && (i.shippingCost ?? 0) > 0);
      final canShowShipping = hasAllShippingCosts;
      final groupShipping = canShowShipping
          ? items.fold<double>(
              0,
              (sum, item) => sum + ((item.shippingCost ?? 0) * item.quantity),
            )
          : null;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Card(
            margin: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        countryLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppConfig.textColor,
                            ),
                      ),
                    ),
                    Text(
                      '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                          ),
                    ),
                  ],
                ),
                subtitle: Text(
                  groupShipping != null
                      ? (allReviewed
                          ? 'Shipping: \$${groupShipping.toStringAsFixed(2)}'
                          : 'Estimated shipping: \$${groupShipping.toStringAsFixed(2)}')
                      : 'Shipping: Pending review',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: groupShipping != null ? AppConfig.primaryColor : AppConfig.subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in items) ...[
                    _CartItemCard(
                      item: item,
                      isLoading: loadingItemId == item.id,
                      onRemove: () async {
                        ref.read(loadingCartItemIdProvider.notifier).state = item.id;
                        try {
                          await cartNotifier.removeItem(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from cart'),
                                backgroundColor: AppConfig.successGreen,
                              ),
                            );
                          }
                        } finally {
                          ref.read(loadingCartItemIdProvider.notifier).state = null;
                        }
                      },
                      onQuantityChanged: (q) async {
                        ref.read(loadingCartItemIdProvider.notifier).state = item.id;
                        try {
                          await cartNotifier.updateQuantity(item.id, q);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cart updated'),
                                backgroundColor: AppConfig.successGreen,
                              ),
                            );
                          }
                        } finally {
                          ref.read(loadingCartItemIdProvider.notifier).state = null;
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartItemsProvider);
    final cartNotifier = ref.read(cartItemsProvider.notifier);
    final addressesAsync = ref.watch(addressesProvider);
    final defaultAddress = addressesAsync.valueOrNull
        ?.where((a) => a.isDefault)
        .firstOrNull;
    final hasDefaultAddress =
        defaultAddress != null && defaultAddress.addressLine.trim().isNotEmpty;

    final loadingItemId = ref.watch(loadingCartItemIdProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(cartItemsProvider.notifier).loadItems(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: const [
              SizedBox(height: AppSpacing.xl),
              CartEmptyContent(),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            Consumer(
              builder: (context, ref, _) {
                final isClearing = ref.watch(clearingCartProvider);
                return TextButton(
                  onPressed: isClearing
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear Cart'),
                              content: const Text('Are you sure you want to remove all items?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref.read(clearingCartProvider.notifier).state = true;
                            try {
                              await cartNotifier.clear();
                            } finally {
                              ref.read(clearingCartProvider.notifier).state = false;
                            }
                          }
                        },
                  child: isClearing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Clear'),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!hasDefaultAddress)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a default address to calculate shipping',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Shipping estimates depend on your default shipping address. Please add an address and set it as default.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppConfig.subtitleColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.myAddresses),
                        child: const Text('Add Address'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(cartItemsProvider.notifier).loadItems(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: _buildGroupedSections(context, ref, cartItems, cartNotifier, loadingItemId),
                  ),
                ),
              ),
              _CartSummary(
                cartNotifier: cartNotifier,
                cartItems: cartItems,
                hasDefaultAddress: hasDefaultAddress,
              ),
            ],
          ),
          if (ref.watch(clearingCartProvider))
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    this.isLoading = false,
  });

  final CartItem item;
  final Future<void> Function() onRemove;
  final Future<void> Function(int) onQuantityChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasShipping = item.shippingCost != null && item.shippingCost! > 0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: () {
                    final url = resolveAssetUrl(item.imageUrl, ApiClient.safeBaseUrl);
                    return url != null && url.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                            child: CachedNetworkImage(
                              imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image_outlined,
                              color: AppConfig.subtitleColor,
                            ),
                          ),
                        )
                    : const Icon(
                          Icons.image_outlined,
                          color: AppConfig.subtitleColor,
                        );
              }(),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Review status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.isReviewed
                              ? AppConfig.successGreen.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isReviewed ? 'REVIEWED' : 'PENDING REVIEW',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: item.isReviewed ? AppConfig.successGreen : Colors.orange.shade800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.variationText != null && item.variationText!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.variationText!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.primaryColor,
                              ),
                        ),
                      ],
                      if (item.storeName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.storeName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.subtitleColor,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ${item.currency}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppConfig.subtitleColor,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} ${item.currency}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.primaryColor,
                                ),
                          ),
                        ],
                      ),
                      if (hasShipping)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.isReviewed
                                ? 'Shipping: \$${(item.shippingCost! * item.quantity).toStringAsFixed(2)}'
                                : 'Estimated shipping: \$${(item.shippingCost! * item.quantity).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                ),
                          ),
                        ),
                      if (!hasShipping)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Shipping: Pending review',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppConfig.errorRed),
                        )
                      : const Icon(Icons.delete_outline),
                  color: AppConfig.errorRed,
                  onPressed: isLoading ? null : () => onRemove(),
                ),
              ],
            ),
            // Quantity controls
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        onPressed: item.quantity > 1
                            ? () => onQuantityChanged(item.quantity - 1)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppConfig.borderColor,
                          foregroundColor: AppConfig.textColor,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${item.quantity}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => onQuantityChanged(item.quantity + 1),
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({
    required this.cartNotifier,
    required this.cartItems,
    required this.hasDefaultAddress,
  });

  final CartNotifier cartNotifier;
  final List<CartItem> cartItems;
  final bool hasDefaultAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewedItems = cartItems.where((i) => i.isReviewed).toList();
    final pendingItemsCount = cartItems.length - reviewedItems.length;
    final subtotalReviewed = reviewedItems.fold<double>(
      0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    final itemCountReviewed =
        reviewedItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final canProceed = hasDefaultAddress && reviewedItems.isNotEmpty;

    final hasAllShippingCosts = reviewedItems.isNotEmpty &&
        reviewedItems.every((i) => i.shippingCost != null && (i.shippingCost ?? 0) > 0);
    final canShowShipping = hasAllShippingCosts;
    final totalShipping = canShowShipping
        ? reviewedItems.fold<double>(
            0,
            (sum, item) => sum + ((item.shippingCost ?? 0) * item.quantity),
          )
        : null;
    final grandTotal =
        totalShipping != null ? subtotalReviewed + totalShipping : null;
    final allReviewed = pendingItemsCount == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppConfig.borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($itemCountReviewed ${itemCountReviewed == 1 ? 'item' : 'items'})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                Text(
                  '\$${subtotalReviewed.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (pendingItemsCount > 0) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$pendingItemsCount item(s) pending review will not be included in checkout.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                Text(
                  totalShipping != null
                      ? (allReviewed
                          ? '\$${totalShipping.toStringAsFixed(2)}'
                          : 'Estimated \$${totalShipping.toStringAsFixed(2)}')
                      : 'Pending review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  grandTotal != null
                      ? (allReviewed
                          ? '\$${grandTotal.toStringAsFixed(2)}'
                          : 'Estimated \$${grandTotal.toStringAsFixed(2)}')
                      : 'Pending review',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppConfig.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, _) {
                final isProceeding = ref.watch(proceedingToCheckoutProvider);
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (isProceeding || !canProceed)
                        ? null
                        : () async {
                            if (!hasDefaultAddress) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please add and set a default address to calculate shipping.'),
                                ),
                              );
                              return;
                            }
                            ref.read(proceedingToCheckoutProvider.notifier).state = true;
                            try {
                              await context.push(AppRoutes.reviewPay);
                            } finally {
                              ref.read(proceedingToCheckoutProvider.notifier).state = false;
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isProceeding
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(!hasDefaultAddress ? 'Add address to continue' : 'Proceed to Checkout'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

