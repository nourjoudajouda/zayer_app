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
                final r = list[i];
                return _RequestCard(item: r);
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final FundingRequestItem item;

  @override
  Widget build(BuildContext context) {
    final methodLabel = item.isZelle ? 'Zelle' : 'Wire transfer';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppConfig.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    FundingRequestsHistoryScreen._statusLabel(item.status),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor:
                      FundingRequestsHistoryScreen._statusColor(item.status),
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${item.amount.toStringAsFixed(2)} ${item.currency}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Submitted: ${item.createdAtLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
            if (item.reviewedAtLabel != null) ...[
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
            if (item.reference != null && item.reference!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reference: ${item.reference}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.userNotes != null && item.userNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Your notes',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              Text(
                item.userNotes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.teamMessage != null &&
                item.teamMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConfig.primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message from support',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConfig.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.teamMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  item.proofAttached ? Icons.attachment : Icons.attach_file,
                  size: 16,
                  color: AppConfig.subtitleColor,
                ),
                const SizedBox(width: 6),
                Text(
                  item.proofAttached ? 'Proof uploaded' : 'No proof file',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                if (item.proofAttached &&
                    item.proofUrl != null &&
                    item.proofUrl!.isNotEmpty) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final u = Uri.tryParse(item.proofUrl!);
                      if (u != null && await canLaunchUrl(u)) {
                        await launchUrl(u, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Open proof'),
                  ),
                ],
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
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
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
