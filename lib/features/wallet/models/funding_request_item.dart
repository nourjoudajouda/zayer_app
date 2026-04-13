/// One manual wallet funding request (wire or Zelle) from API.
class FundingRequestItem {
  const FundingRequestItem({
    required this.id,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAtLabel,
    this.reviewedAtLabel,
    this.approvedAtLabel,
    this.reference,
    this.userNotes,
    this.teamMessage,
    this.proofAttached = false,
    this.proofUrl,
  });

  final String id;
  final String method;
  final double amount;
  final String currency;
  final String status;
  final String createdAtLabel;
  final String? reviewedAtLabel;
  final String? approvedAtLabel;
  final String? reference;
  final String? userNotes;
  final String? teamMessage;
  final bool proofAttached;
  final String? proofUrl;

  bool get isWire => method == 'wire_transfer';
  bool get isZelle => method == 'zelle';

  factory FundingRequestItem.fromJson(Map<String, dynamic> json) {
    final created = json['created_at']?.toString() ?? '';
    final reviewed = json['reviewed_at']?.toString();
    final approved = json['approved_at']?.toString();
    return FundingRequestItem(
      id: json['id']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      createdAtLabel: _shortDate(created),
      reviewedAtLabel: reviewed != null && reviewed.isNotEmpty
          ? _shortDate(reviewed)
          : null,
      approvedAtLabel: approved != null && approved.isNotEmpty
          ? _shortDate(approved)
          : null,
      reference: json['reference']?.toString(),
      userNotes: json['notes']?.toString(),
      teamMessage: (json['team_message'] ?? json['admin_notes'])?.toString(),
      proofAttached: json['proof_attached'] == true,
      proofUrl: json['proof_url']?.toString(),
    );
  }

  static String _shortDate(String iso) {
    if (iso.length < 10) return iso;
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
