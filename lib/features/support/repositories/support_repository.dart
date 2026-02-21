import '../models/support_models.dart';

/// Mock support data. Replace with API: GET /api/support/tickets, /api/orders.
class SupportRepository {
  Future<List<SupportInboxItem>> getInboxItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return [
      const SupportInboxItem(
        id: 'zy-9901',
        title: '#ZY-9901',
        subtitle: 'Consolidated Shipment',
        status: 'IN TRANSIT',
        statusColor: 0xFF10B981,
        orderId: 'Order #ZY-9901',
        timeAgo: '2h ago',
        isTicket: false,
      ),
      const SupportInboxItem(
        id: 'zy-9902',
        title: '#ZY-9902',
        subtitle: 'Express Delivery',
        status: 'PENDING',
        statusColor: 0xFF3B82F6,
        orderId: 'Order #ZY-9901',
        timeAgo: '2h ago',
        isTicket: false,
      ),
      const SupportInboxItem(
        id: 'sup-882901',
        title: 'SUP-882901',
        subtitle: 'Billing Discrepancy',
        status: 'MED',
        statusColor: 0xFFF59E0B,
        orderId: 'Order #ZY-9905',
        timeAgo: '5h ago',
        isTicket: true,
      ),
      const SupportInboxItem(
        id: 'sup-882742',
        title: 'SUP-882742',
        subtitle: 'Address Correction',
        status: 'RESOLVED',
        statusColor: 0xFF6B7280,
        orderId: 'Order #ZY-9890',
        timeAgo: 'Yesterday',
        isTicket: true,
      ),
    ];
  }

  Future<SupportTicketDetail> getTicketDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return SupportTicketDetail(
      id: id,
      status: 'IN PROGRESS',
      avgResponseTime: '2h',
      orderId: 'ZX-9901',
      events: const [
        SupportTicketEvent(label: 'Ticket Created', time: 'Oct 24, 10:00 AM'),
        SupportTicketEvent(label: 'Agent Assigned', time: 'Oct 24, 10:05 AM'),
      ],
      messages: const [
        SupportChatMessage(
          id: '1',
          isFromAgent: true,
          senderName: 'Sarah - Support',
          body: 'Hello! I\'m Sarah from the logistics team. I see you\'re having an issue with the delivery status of order #ZX-9901. Could you please provide a photo of the package if it has arrived?',
          timestamp: '10:06 AM',
        ),
        SupportChatMessage(
          id: '2',
          isFromAgent: false,
          senderName: 'You',
          body: 'Hi Sarah, the app says it was delivered but I only received part of the order. Here is the box I got.',
          timestamp: '10:12 AM',
        ),
      ],
    );
  }

  Future<String> submitSupportRequest({
    required String orderId,
    required String issueType,
    required String details,
    List<String>? attachmentPaths,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'SUP-882910';
  }
}
