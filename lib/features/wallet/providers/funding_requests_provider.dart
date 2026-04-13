import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/funding_request_item.dart';

/// GET /api/wallet/funding-requests — Wire & Zelle request history.
final fundingRequestsProvider =
    FutureProvider.autoDispose<List<FundingRequestItem>>((ref) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/wallet/funding-requests',
  );
  final list = res.data?['wallet_topup_requests'];
  if (list is! List) return const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(FundingRequestItem.fromJson)
      .toList();
});
