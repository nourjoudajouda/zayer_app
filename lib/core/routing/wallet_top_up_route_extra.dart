/// Extra for [AppRoutes.topUpWallet] / [AppRoutes.paymentMethods] when returning to Purchase Assistant after top-up.
class WalletTopUpRouteExtra {
  const WalletTopUpRouteExtra({
    this.initialAmount,
    this.returnPurchaseAssistantRequestId,
  });

  final double? initialAmount;

  /// When set, successful card top-up pops with `true` so the PA detail screen can refresh and continue payment.
  final String? returnPurchaseAssistantRequestId;
}
