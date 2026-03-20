import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import '../cart/providers/cart_providers.dart';
import 'models/address_model.dart';
import 'providers/profile_providers.dart';
import 'widgets/action_card.dart';
import 'widgets/badge_pill.dart';

/// My Addresses screen. Opened from Review & Pay "Change" or from Profile.
/// Pops with [true] when user saves/selects a different address so caller can show recalculation warning.
class MyAddressesScreen extends ConsumerWidget {
  const MyAddressesScreen({super.key, this.openedFromCart = false});

  /// True when opened from cart checkout gate (prompt to pick default).
  final bool openedFromCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Text(openedFromCart ? 'Delivery address' : 'My Addresses'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (addresses) => _MyAddressesContent(
          addresses: addresses,
          openedFromCart: openedFromCart,
        ),
      ),
    );
  }
}

class _MyAddressesContent extends ConsumerWidget {
  const _MyAddressesContent({required this.addresses, this.openedFromCart = false});

  final List<Address> addresses;
  final bool openedFromCart;

  Future<void> _onEdit(BuildContext context, WidgetRef ref, Address address) async {
    if (address.isLocked) return;
    final saved = await context.push<bool>(
      AppRoutes.addEditAddress,
      extra: _addressToExtra(address),
    );
    if (context.mounted && saved == true) {
      ref.invalidate(addressesProvider);
      context.pop(true);
    }
  }

  Map<String, dynamic> _addressToExtra(Address address) {
    return <String, dynamic>{
      'isEdit': true,
      'addressId': address.id,
      'address': address.addressLine,
      'countryId': address.countryId,
      'countryName': address.countryName,
      'cityId': address.cityId,
      'cityName': address.cityName,
      'phone': address.phone,
      'isDefault': address.isDefault,
      'nickname': address.nickname,
      'addressType': address.addressType.index,
      'areaDistrict': address.areaDistrict,
      'streetAddress': address.streetAddress,
      'buildingVillaSuite': address.buildingVillaSuite,
      'lat': address.lat,
      'lng': address.lng,
    };
  }

  Future<void> _onAddNew(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>(
      AppRoutes.addEditAddress,
      extra: <String, dynamic>{
        'isEdit': false,
        if (openedFromCart && addresses.isEmpty) 'requireDefault': true,
      },
    );
    if (context.mounted && saved == true) {
      ref.invalidate(addressesProvider);
      context.pop(true);
    }
  }

  Future<void> _onSetDefault(BuildContext context, WidgetRef ref, String addressId) async {
    ref.read(setDefaultAddressLoadingIdProvider.notifier).state = addressId;
    try {
      await ref.read(addressRepositoryProvider).setDefaultAddress(addressId);
      ref.invalidate(addressesProvider);
      await ref.read(cartItemsProvider.notifier).loadItems();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default address updated')));
        if (openedFromCart) {
          context.pop(true);
        }
      }
    } finally {
      ref.read(setDefaultAddressLoadingIdProvider.notifier).state = null;
    }
  }

  void _onCopy(BuildContext context, Address address) {
    Clipboard.setData(ClipboardData(text: address.addressLine));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull;
    final otherAddresses = addresses.where((a) => !a.isDefault).toList();

    if (addresses.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (openedFromCart) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Choose where we ship your cart. Your first address will be saved as the default for shipping quotes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.textColor),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppConfig.subtitleColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'No addresses yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppConfig.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add an address and set it as default for shipping and checkout.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => _onAddNew(context, ref),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 22),
                  label: const Text('Add New Address'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(addressesProvider);
        await ref.read(addressesProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (addresses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppConfig.primaryColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.defaultAddressChangeCartReviewNote ??
                          'Note: If you change your default delivery address, all items in your cart will be sent for admin review again.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (openedFromCart && defaultAddress == null && addresses.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No default address yet. Tap “Set as default” on one of your addresses below.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // PRIMARY RESIDENCE
          if (defaultAddress != null) ...[
            Text(
              'PRIMARY RESIDENCE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PrimaryResidenceCard(
              address: defaultAddress,
              isLoadingSetDefault: ref.watch(setDefaultAddressLoadingIdProvider) == defaultAddress.id,
              onEdit: () => _onEdit(context, ref, defaultAddress),
              onSetDefault: () => _onSetDefault(context, ref, defaultAddress.id),
              onCopy: () => _onCopy(context, defaultAddress),
              onUsage: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          // OTHER LOCATIONS
          if (otherAddresses.isNotEmpty) ...[
            Text(
              'OTHER LOCATIONS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...otherAddresses.map((address) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _OtherLocationCard(
                    address: address,
                    onEdit: address.isLocked ? null : () => _onEdit(context, ref, address),
                    onSetDefault: address.isLocked
                        ? null
                        : () => _onSetDefault(context, ref, address.id),
                    isSettingDefault:
                        ref.watch(setDefaultAddressLoadingIdProvider) == address.id,
                  ),
                )),
            const SizedBox(height: AppSpacing.md),
          ],
          // Legal & Logistics Policy
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: AppConfig.subtitleColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Legal & Logistics Policy: Addresses linked to active orders or customs clearance processes cannot be modified until delivery is complete. Changes to addresses may impact regional pricing, tax calculations, and shipping timelines.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _onAddNew(context, ref),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add New Address'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    ),
    );
  }
}

class _PrimaryResidenceCard extends StatelessWidget {
  const _PrimaryResidenceCard({
    required this.address,
    required this.onEdit,
    required this.onSetDefault,
    required this.onCopy,
    required this.onUsage,
    this.isLoadingSetDefault = false,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onCopy;
  final VoidCallback onUsage;
  final bool isLoadingSetDefault;

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map
            Stack(
              alignment: Alignment.topLeft,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: address.lat != null && address.lng != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(address.lat!, address.lng!),
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('addr'),
                                position: LatLng(address.lat!, address.lng!),
                              ),
                            },
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            zoomGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                          ),
                        )
                      : Container(
                          color: AppConfig.borderColor.withValues(alpha: 0.5),
                          child: Center(
                            child: Icon(Icons.map_outlined, size: 48, color: AppConfig.subtitleColor),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: BadgePill(
                    label: 'DEFAULT',
                    icon: Icons.star,
                    color: AppConfig.primaryColor,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppConfig.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        color: AppConfig.primaryColor,
                        iconSize: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.addressLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppConfig.subtitleColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (address.isVerified)
                        BadgePill(label: 'VERIFIED', icon: Icons.check_circle_outline, color: AppConfig.successGreen),
                      if (address.isResidential)
                        BadgePill(label: 'RESIDENTIAL', icon: Icons.home_outlined, color: AppConfig.primaryColor),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _ActionChip(
                        icon: Icons.check_circle_outline,
                        label: 'Default',
                        onTap: isLoadingSetDefault ? null : onSetDefault,
                        isLoading: isLoadingSetDefault,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionChip(icon: Icons.copy_outlined, label: 'Copy', onTap: onCopy),
                      const SizedBox(width: AppSpacing.md),
                      _ActionChip(icon: Icons.history, label: 'Usage', onTap: onUsage),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap, this.isLoading = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppConfig.primaryColor),
              )
            else
              Icon(icon, size: 18, color: AppConfig.subtitleColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherLocationCard extends StatelessWidget {
  const _OtherLocationCard({
    required this.address,
    this.onEdit,
    this.onSetDefault,
    this.isSettingDefault = false,
  });

  final Address address;
  final VoidCallback? onEdit;
  final VoidCallback? onSetDefault;
  final bool isSettingDefault;

  @override
  Widget build(BuildContext context) {
    final icon = address.addressType == AddressType.office
        ? Icons.work_outline
        : address.addressType == AddressType.home
            ? Icons.home_outlined
            : Icons.warehouse_outlined;

    return ActionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppConfig.subtitleColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.displayTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppConfig.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        color: AppConfig.primaryColor,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 20, color: AppConfig.subtitleColor),
                          Text(
                            'LOCKED',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.addressLine,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
                ),
                if (address.linkedToActiveOrder) ...[
                  const SizedBox(height: 8),
                  BadgePill(
                    label: 'LINKED TO ACTIVE ORDER',
                    icon: Icons.local_shipping_outlined,
                    color: AppConfig.warningOrange,
                  ),
                ],
                if (onSetDefault != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: isSettingDefault ? null : onSetDefault,
                      icon: isSettingDefault
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConfig.primaryColor,
                              ),
                            )
                          : const Icon(Icons.star_outline, size: 18),
                      label: Text(isSettingDefault ? 'Setting default…' : 'Set as default'),
                      style: TextButton.styleFrom(foregroundColor: AppConfig.primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
