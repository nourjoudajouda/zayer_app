import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_refund_to_wallet_model.dart';
import '../wallet_financial_api.dart';

final walletRefundsToWalletProvider =
    FutureProvider.autoDispose<List<WalletRefundToWalletModel>>((ref) async {
  return fetchWalletRefundsToWallet();
});
