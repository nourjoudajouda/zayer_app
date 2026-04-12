import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_withdrawal_model.dart';
import '../wallet_financial_api.dart';

final walletWithdrawalsProvider =
    FutureProvider.autoDispose<List<WalletWithdrawalModel>>((ref) async {
  return fetchWalletWithdrawals();
});
