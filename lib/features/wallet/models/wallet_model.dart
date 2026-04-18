/// Wallet balance breakdown and activity. API: GET /api/wallet later.
class WalletBalance {
  const WalletBalance({
    required this.available,
    required this.pending,
    required this.promo,
  });

  final double available;
  final double pending;
  final double promo;

  String get availableFormatted => '\$${available.toStringAsFixed(2)}';
  String get pendingFormatted => '\$${pending.toStringAsFixed(0)}';
  String get promoFormatted => '\$${promo.toStringAsFixed(0)}';
}

/// Sub-type for payment rows from API `flow` (wallet transaction history).
enum WalletTransactionFlow {
  shipmentPayment,
  purchaseAssistantPayment,
  orderPayment,
  walletTopup,
  walletRefund,
  withdrawal,
  adminAdjustment,
  cardVerification,
  other,
}

enum WalletActivityType {
  all,
  /// API `refund_in` — refund from order/shipment to wallet.
  refundToWallet,
  /// API `withdraw_out` — withdraw to bank.
  withdrawToBank,
  /// Legacy `refund` type rows.
  refunds,
  payments,
  topUps,
  adminCredits,
  /// Card verification / saved-card / manual funding credits.
  fundingCredits,
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.dateTime,
    required this.amount,
    required this.subtitle,
    this.isCredit = false,
    this.flow = WalletTransactionFlow.other,
  });

  final String id;
  final WalletActivityType type;
  final String title;
  final String dateTime;
  final String amount;
  final String subtitle;
  final bool isCredit;
  final WalletTransactionFlow flow;
}
