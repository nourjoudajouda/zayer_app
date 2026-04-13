import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_error_message.dart';
import '../../core/theme/app_spacing.dart';
import 'models/funding_request_item.dart';
import 'providers/funding_requests_provider.dart';

/// Wire & Zelle funding request history (pending → approved/rejected).
class FundingRequestsHistoryScreen extends ConsumerWidget {
  const FundingRequestsHistoryScreen({super.key});

  static String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return AppConfig.successGreen;
      case 'rejected':
        return Colors.red.shade700;
      case 'under_review':
        return AppConfig.warningOrange;
      default:
        return AppConfig.subtitleColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fundingRequestsProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Funding requests'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No wire or Zelle requests yet. Submit one from Add funds.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fundingRequestsProvider);
              await ref.read(fundingRequestsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length,
              itemBuilder: (context, i) {
                return _FundingRequestTile(
                  item: list[i],
                  statusLabel: FundingRequestsHistoryScreen._statusLabel,
                  statusColor: FundingRequestsHistoryScreen._statusColor,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              userFacingApiMessage(e),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _FundingRequestTile extends StatelessWidget {
  const _FundingRequestTile({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
  });

  final FundingRequestItem item;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;

  @override
  Widget build(BuildContext context) {
    final methodLabel = item.isZelle ? 'Zelle' : 'Wire transfer';
    final st = item.status;
    final chipColor = statusColor(st);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: AppConfig.cardColor,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  methodLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Chip(
                label: Text(
                  statusLabel(st),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: chipColor,
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${item.amount.toStringAsFixed(2)} ${item.currency}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted: ${item.createdAtLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            _ExpandSection(
              title: 'Sender details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_has(item.senderName))
                    _kv(context, 'Name', item.senderName!),
                  if (_has(item.senderEmail))
                    _kv(context, 'Email', item.senderEmail!),
                  if (_has(item.senderPhone))
                    _kv(context, 'Phone', item.senderPhone!),
                  if (item.isWire && _has(item.bankName))
                    _kv(context, 'Bank', item.bankName!),
                  if (!_hasAnySender(item))
                    Text(
                      'No sender details were provided.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                          ),
                    ),
                ],
              ),
            ),
            if (_has(item.reference)) ...[
              const SizedBox(height: 12),
              _ExpandSection(
                title: 'Reference',
                child: SelectableText(
                  item.reference!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (_has(item.userNotes)) ...[
              const SizedBox(height: 12),
              _ExpandSection(
                title: 'Your notes',
                child: Text(
                  item.userNotes!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (item.reviewedAtLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reviewed: ${item.reviewedAtLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
            ],
            if (item.approvedAtLabel != null) ...[
              Text(
                'Approved: ${item.approvedAtLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
            ],
            if (st == 'rejected') ...[
              if (_rejectionText(item) != null) ...[
                const SizedBox(height: 12),
                _MessagePanel(
                  title: 'Rejection reason',
                  body: _rejectionText(item)!,
                  borderColor: Colors.red.shade700,
                  backgroundColor: Colors.red.shade50,
                ),
              ],
            ] else if (_has(item.teamMessage)) ...[
              const SizedBox(height: 12),
              _MessagePanel(
                title: 'Message from support',
                body: item.teamMessage!,
                borderColor: AppConfig.primaryColor,
                backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.08),
              ),
            ],
            const SizedBox(height: 12),
            _ExpandSection(
              title: 'Proof',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.proofAttached ? Icons.attachment : Icons.attach_file,
                        size: 18,
                        color: AppConfig.subtitleColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.proofAttached
                              ? 'A file was attached to this request.'
                              : 'No proof file was uploaded.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (item.proofAttached &&
                          item.proofUrl != null &&
                          item.proofUrl!.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            final u = Uri.tryParse(item.proofUrl!);
                            if (u != null && await canLaunchUrl(u)) {
                              await launchUrl(
                                u,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: const Text('Open'),
                        ),
                    ],
                  ),
                  if (item.proofUrl != null &&
                      item.proofUrl!.isNotEmpty &&
                      _isImageUrl(item.proofUrl!)) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.proofUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _has(String? s) => s != null && s.trim().isNotEmpty;

  static String? _rejectionText(FundingRequestItem item) {
    final r = item.rejectionReason?.trim();
    if (r != null && r.isNotEmpty) return r;
    final t = item.teamMessage?.trim();
    if (t != null && t.isNotEmpty) return t;
    return null;
  }

  static bool _hasAnySender(FundingRequestItem item) {
    return _has(item.senderName) ||
        _has(item.senderEmail) ||
        _has(item.senderPhone) ||
        (item.isWire && _has(item.bankName));
  }

  static Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
          ),
          SelectableText(v, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('image');
  }
}

class _ExpandSection extends StatelessWidget {
  const _ExpandSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConfig.subtitleColor,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.body,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String title;
  final String body;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: borderColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
