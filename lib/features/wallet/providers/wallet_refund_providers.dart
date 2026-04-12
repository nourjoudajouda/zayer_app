import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_refund_request_model.dart';
import '../wallet_refund_api.dart';

final walletRefundRequestsProvider =
    FutureProvider.autoDispose<List<WalletRefundRequestModel>>((ref) async {
  return fetchWalletRefundRequests();
});
