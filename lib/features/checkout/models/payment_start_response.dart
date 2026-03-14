/// Response from POST /api/orders/{orderId}/pay (Square checkout start).
class PaymentStartResponse {
  const PaymentStartResponse({
    required this.paymentId,
    required this.reference,
    this.checkoutUrl,
    required this.status,
  });

  final int paymentId;
  final String reference;
  final String? checkoutUrl;
  final String status;

  factory PaymentStartResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStartResponse(
      paymentId: _parseInt(json['payment_id']),
      reference: (json['reference'] ?? '').toString(),
      checkoutUrl: (json['checkout_url'] as String?)?.trim(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is num) return v.toInt();
  return 0;
}
