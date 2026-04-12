import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/wallet_refund_request_model.dart';

Future<List<WalletRefundRequestModel>> fetchWalletRefundRequests() async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/refund-requests',
  );
  final raw = res.data?['refund_requests'];
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(WalletRefundRequestModel.fromJson)
      .toList();
}

Future<WalletRefundRequestModel?> fetchWalletRefundRequest(String id) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/refund-requests/$id',
  );
  final m = res.data?['refund_request'];
  if (m is Map<String, dynamic>) {
    return WalletRefundRequestModel.fromJson(m);
  }
  return null;
}

Future<({bool ok, Map<String, dynamic> data})> createWalletRefundRequest({
  required double amount,
  required String reason,
  required String iban,
  required String bankName,
  required String country,
}) async {
  final res = await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/wallet/refund-requests',
    data: {
      'amount': amount,
      'reason': reason,
      'iban': iban,
      'bank_name': bankName,
      'country': country,
    },
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  final data = Map<String, dynamic>.from(res.data ?? {});
  final ok = res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;
  return (ok: ok, data: data);
}
