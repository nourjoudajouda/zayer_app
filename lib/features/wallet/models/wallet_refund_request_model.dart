class WalletRefundRequestModel {
  const WalletRefundRequestModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.iban,
    required this.bankName,
    required this.country,
    required this.status,
    this.adminNotes,
    this.createdAt,
    this.reviewedAt,
    this.processedAt,
    this.transferredAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String reason;
  final String iban;
  final String bankName;
  final String country;
  final String status;
  final String? adminNotes;
  final String? createdAt;
  final String? reviewedAt;
  final String? processedAt;
  final String? transferredAt;

  factory WalletRefundRequestModel.fromJson(Map<String, dynamic> j) {
    return WalletRefundRequestModel(
      id: j['id']?.toString() ?? '',
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      currency: (j['currency'] ?? 'USD').toString(),
      reason: (j['reason'] ?? '').toString(),
      iban: (j['iban'] ?? '').toString(),
      bankName: (j['bank_name'] ?? '').toString(),
      country: (j['country'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      adminNotes: j['admin_notes'] as String?,
      createdAt: j['created_at'] as String?,
      reviewedAt: j['reviewed_at'] as String?,
      processedAt: j['processed_at'] as String?,
      transferredAt: j['transferred_at'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'processed':
        return 'Processed';
      case 'transferred':
        return 'Transferred';
      default:
        return status;
    }
  }
}
