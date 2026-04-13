import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/wallet_model.dart';

/// Wallet balance from API: GET /api/wallet
final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>(
      '/api/wallet',
    );
    final d = res.data;
    if (d != null) {
      return WalletBalance(
        available: (d['available'] as num?)?.toDouble() ?? 0,
        pending: (d['pending'] as num?)?.toDouble() ?? 0,
        promo: (d['promo'] as num?)?.toDouble() ?? 0,
      );
    }
  } catch (_) {}
  return const WalletBalance(available: 0, pending: 0, promo: 0);
});

/// Balance visibility (hide/show amount).
final walletBalanceVisibleProvider = StateProvider<bool>((_) => true);

/// Activity filter: All | Refunds | Payments | Top-ups.
final walletActivityFilterProvider = StateProvider<WalletActivityType>(
  (_) => WalletActivityType.all,
);

/// Transactions from API: GET /api/wallet/activity
final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>(
      '/api/wallet/activity',
    );
    final list = res.data;
    if (list != null) {
      return list.whereType<Map<String, dynamic>>().map((t) {
        final typeStr = t['type'] as String?;
        var type = WalletActivityType.topUps;
        if (typeStr == 'payment' || typeStr == 'payments') {
          type = WalletActivityType.payments;
        }
        if (typeStr == 'refund_in') {
          type = WalletActivityType.refundToWallet;
        } else if (typeStr == 'withdraw_out') {
          type = WalletActivityType.withdrawToBank;
        } else if (typeStr == 'refund' || typeStr == 'refunds') {
          type = WalletActivityType.refunds;
        }
        if (typeStr == 'admin_credit' || typeStr == 'admin-credits') {
          type = WalletActivityType.adminCredits;
        }
        if (typeStr == 'top_up') {
          type = WalletActivityType.topUps;
        }
        if (typeStr == 'card_verification_credit' ||
            typeStr == 'card_topup_credit' ||
            typeStr == 'wire_transfer_credit' ||
            typeStr == 'zelle_credit') {
          type = WalletActivityType.fundingCredits;
        }
        return WalletTransaction(
          id: (t['id'] ?? '').toString(),
          type: type,
          title: (t['title'] ?? '').toString(),
          dateTime: (t['date_time'] ?? '').toString(),
          amount: (t['amount'] ?? '').toString(),
          subtitle: (t['subtitle'] ?? '').toString(),
          isCredit: t['is_credit'] == true,
        );
      }).toList();
    }
  } catch (_) {}
  return const [];
});

/// Filtered transactions by activity type.
final walletFilteredTransactionsProvider =
    Provider<AsyncValue<List<WalletTransaction>>>((ref) {
      final async = ref.watch(walletTransactionsProvider);
      final filter = ref.watch(walletActivityFilterProvider);
      return async.when(
        data: (list) {
          if (filter == WalletActivityType.all) return AsyncValue.data(list);
          if (filter == WalletActivityType.fundingCredits) {
            return AsyncValue.data(
              list
                  .where((t) => t.type == WalletActivityType.fundingCredits)
                  .toList(),
            );
          }
          if (filter == WalletActivityType.refundToWallet) {
            return AsyncValue.data(
              list
                  .where(
                    (t) =>
                        t.type == WalletActivityType.refundToWallet ||
                        t.type == WalletActivityType.refunds,
                  )
                  .toList(),
            );
          }
          return AsyncValue.data(list.where((t) => t.type == filter).toList());
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });
