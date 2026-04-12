import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/wallet_refund_to_wallet_model.dart';
import 'models/wallet_withdrawal_model.dart';

Future<List<WalletRefundToWalletModel>> fetchWalletRefundsToWallet() async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/refunds',
  );
  final raw = res.data?['wallet_refunds'];
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(WalletRefundToWalletModel.fromJson)
      .toList();
}

Future<List<WalletWithdrawalModel>> fetchWalletWithdrawals() async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/withdrawals',
  );
  final raw = res.data?['wallet_withdrawals'];
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(WalletWithdrawalModel.fromJson)
      .toList();
}

Future<double> fetchMaxRefundable({
  required String sourceType,
  required int sourceId,
}) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/refundable',
    queryParameters: {
      'source_type': sourceType,
      'source_id': sourceId,
    },
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  if (res.statusCode == 404) return 0;
  final d = res.data;
  if (d is Map<String, dynamic>) {
    return (d['max_refundable'] as num?)?.toDouble() ?? 0;
  }
  return 0;
}

Future<({bool ok, Map<String, dynamic> data})> createRefundToWallet({
  required String sourceType,
  required int sourceId,
  required double amount,
  required String reason,
}) async {
  final res = await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/wallet/refunds',
    data: {
      'source_type': sourceType,
      'source_id': sourceId,
      'amount': amount,
      'reason': reason,
    },
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  final data = Map<String, dynamic>.from(res.data ?? {});
  final ok = res.statusCode != null &&
      res.statusCode! >= 200 &&
      res.statusCode! < 300;
  return (ok: ok, data: data);
}

Future<Map<String, double>> fetchWithdrawalQuote(double amount) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/withdrawals/quote',
    queryParameters: {'amount': amount},
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  final d = res.data;
  if (d is! Map<String, dynamic>) {
    return {
      'requested_amount': amount,
      'fee_percent': 0,
      'fee_amount': 0,
      'net_amount': amount,
    };
  }
  return {
    'requested_amount': (d['requested_amount'] as num?)?.toDouble() ?? amount,
    'fee_percent': (d['fee_percent'] as num?)?.toDouble() ?? 0,
    'fee_amount': (d['fee_amount'] as num?)?.toDouble() ?? 0,
    'net_amount': (d['net_amount'] as num?)?.toDouble() ?? amount,
  };
}

Future<({bool ok, Map<String, dynamic> data})> createWalletWithdrawal({
  required double amount,
  required String iban,
  required String bankName,
  required String country,
  String? note,
}) async {
  final res = await ApiClient.instance.post<Map<String, dynamic>>(
    '/api/wallet/withdrawals',
    data: {
      'amount': amount,
      'iban': iban,
      'bank_name': bankName,
      'country': country,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
    options: Options(validateStatus: (s) => s != null && s < 500),
  );
  final data = Map<String, dynamic>.from(res.data ?? {});
  final ok = res.statusCode != null &&
      res.statusCode! >= 200 &&
      res.statusCode! < 300;
  return (ok: ok, data: data);
}
