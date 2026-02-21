import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'models/support_models.dart';
import 'repositories/support_repository.dart';

/// Ticket chat: header with ticket # and badge, timeline, messages, input.
class SupportTicketChatScreen extends StatefulWidget {
  const SupportTicketChatScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<SupportTicketChatScreen> createState() => _SupportTicketChatScreenState();
}

class _SupportTicketChatScreenState extends State<SupportTicketChatScreen> {
  final SupportRepository _repo = SupportRepository();
  final TextEditingController _messageController = TextEditingController();
  SupportTicketDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _repo.getTicketDetail(widget.ticketId);
    if (mounted) {
      setState(() {
        _detail = d;
        _loading = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _detail == null) return;
    setState(() {
      _detail = SupportTicketDetail(
        id: _detail!.id,
        status: _detail!.status,
        avgResponseTime: _detail!.avgResponseTime,
        orderId: _detail!.orderId,
        events: _detail!.events,
        messages: [
          ..._detail!.messages,
          SupportChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            isFromAgent: false,
            senderName: 'You',
            body: text,
            timestamp: _formatTime(DateTime.now()),
            imageUrl: null,
          ),
        ],
      );
    });
    _messageController.clear();
  }

  String _formatTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final am = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $am';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        appBar: AppBar(
          title: Text('Ticket #${widget.ticketId}'),
          backgroundColor: AppConfig.backgroundColor,
          foregroundColor: AppConfig.textColor,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final d = _detail!;
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Text('Ticket #${d.id}'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          if (d.orderId != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: Text(
                    'Order #${d.orderId}',
                    style: AppTextStyles.bodySmall(AppConfig.textColor),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: Text(
                    d.status,
                    style: AppTextStyles.bodySmall(AppConfig.primaryColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Avg. response time: ${d.avgResponseTime}',
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Timeline
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: d.events.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.label,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                      Text(
                        e.time,
                        style: AppTextStyles.bodySmall(AppConfig.textColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: d.messages.length,
              itemBuilder: (context, i) {
                final m = d.messages[i];
                return _ChatBubble(message: m);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppConfig.cardColor,
              border: Border(top: BorderSide(color: AppConfig.borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {},
                  color: AppConfig.subtitleColor,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppConfig.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: AppConfig.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final SupportChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAgent = message.isFromAgent;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAgent) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.2),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0] : '?',
                style: AppTextStyles.bodySmall(AppConfig.primaryColor),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isAgent
                    ? AppConfig.borderColor.withValues(alpha: 0.3)
                    : AppConfig.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.senderName,
                    style: AppTextStyles.bodySmall(
                      isAgent ? AppConfig.primaryColor : AppConfig.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body,
                    style: AppTextStyles.bodyMedium(AppConfig.textColor),
                  ),
                  Text(
                    message.timestamp,
                    style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  ),
                ],
              ),
            ),
          ),
          if (!isAgent) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
