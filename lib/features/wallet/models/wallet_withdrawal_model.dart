/// Withdraw wallet balance to bank (IBAN).
class WalletWithdrawalModel {
  const WalletWithdrawalModel({
    required this.id,
    required this.amount,
    required this.feePercent,
    required this.feeAmount,
    required this.netAmount,
    required this.iban,
    required this.bankName,
    required this.country,
    required this.status,
    this.note,
    this.adminNotes,
    this.transferProofUrl,
    this.createdAt,
    this.reviewedAt,
    this.transferredAt,
  });

  final String id;
  final double amount;
  final double feePercent;
  final double feeAmount;
  final double netAmount;
  final String iban;
  final String bankName;
  final String country;
  final String status;
  final String? note;
  final String? adminNotes;
  final String? transferProofUrl;
  final String? createdAt;
  final String? reviewedAt;
  final String? transferredAt;

  factory WalletWithdrawalModel.fromJson(Map<String, dynamic> j) {
    return WalletWithdrawalModel(
      id: j['id']?.toString() ?? '',
      amount: (j['amount'] as num?)?.toDouble() ?? 0,
      feePercent: (j['fee_percent'] as num?)?.toDouble() ?? 0,
      feeAmount: (j['fee_amount'] as num?)?.toDouble() ?? 0,
      netAmount: (j['net_amount'] as num?)?.toDouble() ?? 0,
      iban: (j['iban'] ?? '').toString(),
      bankName: (j['bank_name'] ?? '').toString(),
      country: (j['country'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      note: j['note'] as String?,
      adminNotes: j['admin_notes'] as String?,
      transferProofUrl: j['transfer_proof_url'] as String?,
      createdAt: j['created_at'] as String?,
      reviewedAt: j['reviewed_at'] as String?,
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
      case 'transferred':
        return 'Transferred';
      default:
        return status;
    }
  }
}
