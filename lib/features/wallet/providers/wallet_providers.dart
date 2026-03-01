import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wallet_model.dart';

/// Current wallet balance. Replace with API later. StateProvider so top-up can add to it.
final walletBalanceProvider = StateProvider<WalletBalance>((_) => const WalletBalance(
      available: 1240.0,
      pending: 45.0,
      promo: 10.0,
    ));

/// Balance visibility (hide/show amount).
final walletBalanceVisibleProvider = StateProvider<bool>((_) => true);

/// Activity filter: All | Refunds | Payments | Top-ups.
final walletActivityFilterProvider = StateProvider<WalletActivityType>((_) => WalletActivityType.all);

/// Mock transactions. Replace with API: GET /api/wallet/activity.
final walletTransactionsProvider = Provider<List<WalletTransaction>>((_) => [
      const WalletTransaction(
        id: '1',
        type: WalletActivityType.payments,
        title: 'Order #ZY-92841',
        dateTime: 'Sep 24, 2023 • 14:30',
        amount: '- \$120.00',
        subtitle: 'SHIPPING FEE',
        isCredit: false,
      ),
      const WalletTransaction(
        id: '2',
        type: WalletActivityType.refunds,
        title: 'Refund #ZY-10332',
        dateTime: 'Sep 22, 2023 • 09:12',
        amount: '+ \$45.00',
        subtitle: 'PENDING',
        isCredit: true,
      ),
      const WalletTransaction(
        id: '3',
        type: WalletActivityType.payments,
        title: 'Order #ZY-88402',
        dateTime: 'Sep 20, 2023 • 11:45',
        amount: '- \$34.50',
        subtitle: 'HANDLING',
        isCredit: false,
      ),
      const WalletTransaction(
        id: '4',
        type: WalletActivityType.topUps,
        title: 'Top-up',
        dateTime: 'Sep 18, 2023 • 10:00',
        amount: '+ \$200.00',
        subtitle: 'COMPLETED',
        isCredit: true,
      ),
    ]);

/// Filtered transactions by activity type.
final walletFilteredTransactionsProvider = Provider<List<WalletTransaction>>((ref) {
  final list = ref.watch(walletTransactionsProvider);
  final filter = ref.watch(walletActivityFilterProvider);
  if (filter == WalletActivityType.all) return list;
  return list.where((t) => t.type == filter).toList();
});
