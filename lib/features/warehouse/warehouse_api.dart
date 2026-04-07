import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/warehouse_models.dart';

Future<List<WarehouseItemApi>> fetchWarehouseItems() async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/warehouse/items');
  final data = res.data;
  final list = data?['items'];
  if (list is! List) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(WarehouseItemApi.fromJson)
      .toList();
}

Future<({OutboundShipmentApi shipment, Map<String, dynamic> breakdown})> createShipment({
  required List<String> selectedOrderLineItemIds,
  required int destinationAddressId,
}) async {
  final res = await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/shipments/create',
    data: {
      'selected_order_item_ids': selectedOrderLineItemIds.map(int.parse).toList(),
      'destination_address_id': destinationAddressId,
    },
  );
  final data = res.data ?? {};
  final ship = data['shipment'];
  final breakdown = data['breakdown'];
  if (ship is! Map<String, dynamic>) {
    throw StateError('Invalid shipment response');
  }
  return (
    shipment: OutboundShipmentApi.fromJson(ship),
    breakdown: breakdown is Map<String, dynamic>
        ? Map<String, dynamic>.from(breakdown)
        : <String, dynamic>{},
  );
}

Future<List<OutboundShipmentApi>> fetchShipments() async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>('/api/shipments');
  final data = res.data;
  final list = data?['shipments'];
  if (list is! List) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(OutboundShipmentApi.fromJson)
      .toList();
}

Future<Map<String, dynamic>> payShipment({
  required String shipmentId,
  required String paymentMethod,
  String? gateway,
}) async {
  final res = await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/shipments/$shipmentId/pay',
    data: {
      'payment_method': paymentMethod,
      if (gateway != null && gateway.isNotEmpty) 'gateway': gateway,
    },
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  return Map<String, dynamic>.from(res.data ?? {});
}
