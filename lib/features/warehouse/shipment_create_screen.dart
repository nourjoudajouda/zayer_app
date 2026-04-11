import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../profile/models/address_model.dart';
import '../profile/providers/profile_providers.dart';
import 'warehouse_api.dart';

/// Select destination address and create outbound shipment (second payment — shipping).
class ShipmentCreateScreen extends ConsumerStatefulWidget {
  const ShipmentCreateScreen({super.key, required this.selectedLineItemIds});

  final List<String> selectedLineItemIds;

  @override
  ConsumerState<ShipmentCreateScreen> createState() => _ShipmentCreateScreenState();
}

class _ShipmentCreateScreenState extends ConsumerState<ShipmentCreateScreen> {
  String? _addressId;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('New shipment'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load addresses')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Add a shipping address first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConfig.subtitleColor),
                ),
              ),
            );
          }
          Address? def;
          for (final a in addresses) {
            if (a.isDefault) {
              def = a;
              break;
            }
          }
          def ??= addresses.isNotEmpty ? addresses.first : null;
          _addressId ??= def?.id;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Order payment (products) is separate from this shipping payment.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Ship to', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              ...addresses.map((a) {
                return RadioListTile<String>(
                  value: a.id,
                  groupValue: _addressId,
                  onChanged: (v) => setState(() => _addressId = v),
                  title: Text(a.addressLine, maxLines: 2),
                  subtitle: Text('${a.countryName}${a.cityName != null ? ', ${a.cityName}' : ''}'),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${widget.selectedLineItemIds.length} item(s) selected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submitting || _addressId == null ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_submitting ? 'Calculating…' : 'Continue to shipping payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final aid = _addressId;
    if (aid == null) return;
    setState(() => _submitting = true);
    try {
      final addrId = int.tryParse(aid);
      if (addrId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid address id')),
          );
        }
        return;
      }
      final result = await createShipment(
        selectedOrderLineItemIds: widget.selectedLineItemIds,
        destinationAddressId: addrId,
      );
      if (!mounted) return;
      await context.push(
        AppRoutes.shipmentShippingPay,
        extra: {
          'shipmentId': result.shipment.id,
          'total': result.shipment.totalShippingPayment,
          'breakdown': result.breakdown,
          'shipment': result.shipment,
          'checkout_payment_mode': result.checkoutPaymentMode,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
