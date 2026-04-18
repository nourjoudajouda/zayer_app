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

Future<({
  OutboundShipmentApi shipment,
  Map<String, dynamic> breakdown,
  String? checkoutPaymentMode,
})> createShipment({
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
  final modeRaw = data['checkout_payment_mode']?.toString().trim();
  return (
    shipment: OutboundShipmentApi.fromJson(ship),
    breakdown: breakdown is Map<String, dynamic>
        ? Map<String, dynamic>.from(breakdown)
        : <String, dynamic>{},
    checkoutPaymentMode: modeRaw != null && modeRaw.isNotEmpty ? modeRaw : null,
  );
}

/// Abandon a draft shipment (no line locks until paid). DELETE /api/shipments/{id}
Future<void> deleteShipmentDraft(String shipmentId) async {
  await ApiClient.instance.delete<void>('/api/shipments/$shipmentId');
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

/// Customer confirms receipt (shipped → delivered). Optional [rating] 1–5 and [note].
Future<void> confirmShipmentDelivery({
  required String shipmentId,
  int? rating,
  String? note,
}) async {
  await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/shipments/$shipmentId/confirm-delivery',
    data: <String, dynamic>{
      if (rating != null) 'rating': rating,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );
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
