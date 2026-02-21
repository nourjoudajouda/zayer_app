/// Support ticket or order item for inbox. API: GET /api/support/tickets, /api/orders.
class SupportInboxItem {
  const SupportInboxItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.orderId,
    this.timeAgo,
    this.isTicket = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final int statusColor; // hex
  final String? orderId;
  final String? timeAgo;
  final bool isTicket;
}

/// Single chat message. API: GET/POST /api/support/tickets/:id/messages.
class SupportChatMessage {
  const SupportChatMessage({
    required this.id,
    required this.isFromAgent,
    required this.senderName,
    required this.body,
    required this.timestamp,
    this.imageUrl,
  });

  final String id;
  final bool isFromAgent;
  final String senderName;
  final String body;
  final String timestamp;
  final String? imageUrl;
}

/// Ticket detail for chat screen. API: GET /api/support/tickets/:id.
class SupportTicketDetail {
  const SupportTicketDetail({
    required this.id,
    required this.status,
    required this.avgResponseTime,
    this.orderId,
    required this.events,
    required this.messages,
  });

  final String id;
  final String status;
  final String avgResponseTime;
  final String? orderId;
  final List<SupportTicketEvent> events;
  final List<SupportChatMessage> messages;
}

class SupportTicketEvent {
  const SupportTicketEvent({required this.label, required this.time});
  final String label;
  final String time;
}
