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

enum WalletActivityType {
  all,
  refunds,
  payments,
  topUps,
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
  });

  final String id;
  final WalletActivityType type;
  final String title;
  final String dateTime;
  final String amount;
  final String subtitle;
  final bool isCredit;
}
