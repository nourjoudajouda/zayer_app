/// Operational refund tied to an order or shipment (credits wallet when approved).
class WalletRefundToWalletModel {
  const WalletRefundToWalletModel({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    this.adminNotes,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String sourceType;
  final String sourceId;
  final double amount;
  final String currency;
  final String reason;
  final String status;
  final String? adminNotes;
  final String? createdAt;
  final String? reviewedAt;

  factory WalletRefundToWalletModel.fromJson(Map<String, dynamic> j) {
    return WalletRefundToWalletModel(
      id: j['id']?.toString() ?? '',
      sourceType: (j['source_type'] ?? '').toString(),
      sourceId: (j['source_id'] ?? '').toString(),
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      currency: (j['currency'] ?? 'USD').toString(),
      reason: (j['reason'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      adminNotes: j['admin_notes'] as String?,
      createdAt: j['created_at'] as String?,
      reviewedAt: j['reviewed_at'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get sourceLabel =>
      sourceType == 'shipment' ? 'Shipment #$sourceId' : 'Order #$sourceId';
}
