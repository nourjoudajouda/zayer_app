import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/warehouse_models.dart';
import 'warehouse_api.dart';

/// Cached warehouse line items (invalidated on pull-to-refresh / hub tab focus).
final warehouseItemsProvider =
    FutureProvider.autoDispose<List<WarehouseItemApi>>((ref) async {
  return fetchWarehouseItems();
});

/// Cached outbound shipments list.
final outboundShipmentsProvider =
    FutureProvider.autoDispose<List<OutboundShipmentApi>>((ref) async {
  return fetchShipments();
});
