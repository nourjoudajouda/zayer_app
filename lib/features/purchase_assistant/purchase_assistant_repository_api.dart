import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/purchase_assistant_request_model.dart';

class PurchaseAssistantRepositoryApi {
  PurchaseAssistantRepositoryApi({Dio? dio}) : _dio = dio ?? ApiClient.instance;
  final Dio _dio;

  Future<List<PurchaseAssistantRequestModel>> list() async {
    final res = await _dio.get<dynamic>('/api/purchase-assistant-requests');
    final raw = res.data;
    final List<dynamic> list;
    if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List<dynamic>;
    } else if (raw is List) {
      list = raw;
    } else {
      return [];
    }
    return list
        .map((e) => e is Map<String, dynamic>
            ? PurchaseAssistantRequestModel.fromJson(e)
            : null)
        .whereType<PurchaseAssistantRequestModel>()
        .toList();
  }

  Future<PurchaseAssistantRequestModel> fetch(String id) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/purchase-assistant-requests/$id',
    );
    final d = res.data;
    if (d == null) throw StateError('Empty response');
    final inner = d['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(d['data'] as Map<String, dynamic>)
        : d;
    return PurchaseAssistantRequestModel.fromJson(inner);
  }

  Future<PurchaseAssistantRequestModel> submit({
    required String sourceUrl,
    String? title,
    String? details,
    int quantity = 1,
    String? variantDetails,
    double? customerEstimatedPrice,
    String currency = 'USD',
    List<File> images = const [],
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('source_url', sourceUrl));
    form.fields.add(MapEntry('quantity', '$quantity'));
    form.fields.add(MapEntry('currency', currency));
    if (title != null && title.isNotEmpty) {
      form.fields.add(MapEntry('title', title));
    }
    if (details != null && details.isNotEmpty) {
      form.fields.add(MapEntry('details', details));
    }
    if (variantDetails != null && variantDetails.isNotEmpty) {
      form.fields.add(MapEntry('variant_details', variantDetails));
    }
    if (customerEstimatedPrice != null) {
      form.fields.add(
        MapEntry('customer_estimated_price', '$customerEstimatedPrice'),
      );
    }
    for (final f in images) {
      form.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            f.path,
            filename: f.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    final res = await _dio.post<Map<String, dynamic>>(
      '/api/purchase-assistant-requests',
      data: form,
    );
    final d = res.data;
    if (d == null) throw StateError('Empty response');
    final inner = d['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(d['data'] as Map<String, dynamic>)
        : d;
    return PurchaseAssistantRequestModel.fromJson(inner);
  }

  /// POST /api/purchase-assistant-requests/{id}/start-payment — same shape as order pay.
  Future<String?> startPayment(String requestId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/purchase-assistant-requests/$requestId/start-payment',
    );
    final data = res.data;
    if (data == null) return null;
    final payload = (data['data'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(data['data'] as Map<String, dynamic>)
        : Map<String, dynamic>.from(data);
    return (payload['checkout_url'] as String?)?.trim();
  }
}

