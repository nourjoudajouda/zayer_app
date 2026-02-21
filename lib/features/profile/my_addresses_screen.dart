import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/address_model.dart';
import 'providers/profile_providers.dart';
import 'widgets/action_card.dart';
import 'widgets/badge_pill.dart';

/// My Addresses screen. Opened from Review & Pay "Change" or from Profile.
/// Pops with [true] when user saves/selects a different address so caller can show recalculation warning.
class MyAddressesScreen extends ConsumerWidget {
  const MyAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (addresses) => _MyAddressesContent(addresses: addresses),
      ),
    );
  }
}

class _MyAddressesContent extends ConsumerWidget {
  const _MyAddressesContent({required this.addresses});

  final List<Address> addresses;

  Future<void> _onEdit(BuildContext context, WidgetRef ref, Address address) async {
    final saved = await context.push<bool>(
      AppRoutes.addEditAddress,
      extra: <String, dynamic>{
        'isEdit': true,
        'addressId': address.id,
        'address': address.addressLine,
        'countryId': address.countryId,
        'countryName': address.countryName,
        'cityId': address.cityId,
        'cityName': address.cityName,
        'phone': address.phone,
        'isDefault': address.isDefault,
      },
    );
    if (context.mounted && saved == true) {
      ref.invalidate(addressesProvider);
      context.pop(true);
    }
  }

  Future<void> _onAddNew(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>(
      AppRoutes.addEditAddress,
      extra: <String, dynamic>{'isEdit': false},
    );
    if (context.mounted && saved == true) {
      ref.invalidate(addressesProvider);
      context.pop(true);
    }
  }

  Future<void> _onSetDefault(BuildContext context, WidgetRef ref, String addressId) async {
    await ref.read(addressRepositoryProvider).setDefaultAddress(addressId);
    ref.invalidate(addressesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default address updated')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 64, color: AppConfig.subtitleColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No addresses yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () => _onAddNew(context, ref),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add New Address'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SAVED ADDRESSES',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...addresses.map((address) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ActionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (address.countryName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConfig.borderColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                address.countryName,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppConfig.subtitleColor,
                                    ),
                              ),
                            ),
                          if (address.countryName.isNotEmpty) const SizedBox(width: 8),
                          if (address.isDefault)
                            BadgePill(
                              label: 'DEFAULT',
                              icon: Icons.star,
                              color: AppConfig.primaryColor,
                            ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _onEdit(context, ref, address),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        address.addressLine,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConfig.textColor,
                            ),
                      ),
                      if (address.cityName != null && address.cityName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          address.cityName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.subtitleColor,
                              ),
                        ),
                      ],
                      if (address.phone != null && address.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: AppConfig.subtitleColor),
                            const SizedBox(width: 6),
                            Text(
                              address.phone!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppConfig.subtitleColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (!address.isDefault) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: () => _onSetDefault(context, ref, address.id),
                          icon: const Icon(Icons.star_border, size: 18),
                          label: const Text('Set as default'),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.lg),
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
        ],
      ),
    );
  }
}
