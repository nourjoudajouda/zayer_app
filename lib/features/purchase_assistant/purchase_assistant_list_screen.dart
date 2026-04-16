import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_providers.dart';
import 'purchase_assistant_repository_api.dart';
import 'purchase_assistant_ui.dart';
import 'widgets/purchase_assistant_store_avatar.dart';

/// Segments for the Purchase Assistant list (client-side filter on API list).
enum PaListSegment {
  all,
  requests,
  awaitingPayment,
  inProgress,
  completed,
}

bool _matchesSegment(PurchaseAssistantRequestModel r, PaListSegment s) {
  if (s == PaListSegment.all) return true;
  switch (s) {
    case PaListSegment.requests:
      return r.status == 'submitted' || r.status == 'under_review';
    case PaListSegment.awaitingPayment:
      return r.status == 'awaiting_customer_payment' ||
          r.status == 'payment_under_review';
    case PaListSegment.inProgress:
      return const {
        'paid',
        'purchasing',
        'purchased',
        'in_transit_to_warehouse',
        'received_at_warehouse',
      }.contains(r.status);
    case PaListSegment.completed:
      return const {'completed', 'rejected', 'cancelled'}.contains(r.status);
    case PaListSegment.all:
      return true;
  }
}

/// Purchase Assistant: manual pricing requests — separate from [Orders] (import/shipment).
class PurchaseAssistantListScreen extends ConsumerStatefulWidget {
  const PurchaseAssistantListScreen({super.key, this.hubEmbedded = false});

  /// Inside [PostOrderHubScreen]: no back button; hub owns navigation.
  final bool hubEmbedded;

  @override
  ConsumerState<PurchaseAssistantListScreen> createState() =>
      _PurchaseAssistantListScreenState();
}

class _PurchaseAssistantListScreenState
    extends ConsumerState<PurchaseAssistantListScreen> {
  final _repo = PurchaseAssistantRepositoryApi();
  final Set<String> _deletingIds = {};
  PaListSegment _segment = PaListSegment.all;

  Future<void> _openSubmit() async {
    await context.push(AppRoutes.purchaseAssistantSubmit);
    if (mounted) ref.invalidate(purchaseAssistantRequestsProvider);
  }

  Future<void> _confirmAndDelete(PurchaseAssistantRequestModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This removes your submitted request. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deletingIds.add(r.id));
    try {
      await _repo.deleteRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request removed')),
      );
      ref.invalidate(purchaseAssistantRequestsProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Could not delete')
          : 'Could not delete';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(r.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(purchaseAssistantRequestsProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Purchase Assistant'),
        automaticallyImplyLeading: !widget.hubEmbedded,
        leading: widget.hubEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _openSubmit,
            child: const Text('New request'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(purchaseAssistantRequestsProvider);
          await ref.read(purchaseAssistantRequestsProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Center(child: Text('Error: $e')),
            ],
          ),
          data: (items) {
            final filtered =
                items.where((r) => _matchesSegment(r, _segment)).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'We price and buy products from links our app does not import automatically. '
                          'Track your request here — this is not the same as a standard import order.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<PaListSegment>(
                            segments: const [
                              ButtonSegment(
                                value: PaListSegment.all,
                                label: Text('All'),
                              ),
                              ButtonSegment(
                                value: PaListSegment.requests,
                                label: Text('Review'),
                              ),
                              ButtonSegment(
                                value: PaListSegment.awaitingPayment,
                                label: Text('Payment'),
                              ),
                              ButtonSegment(
                                value: PaListSegment.inProgress,
                                label: Text('Progress'),
                              ),
                              ButtonSegment(
                                value: PaListSegment.completed,
                                label: Text('Done'),
                              ),
                            ],
                            selected: {_segment},
                            onSelectionChanged: (s) {
                              setState(() => _segment = s.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          items.isEmpty
                              ? 'No requests yet.\nTap New request to add a product link.'
                              : 'Nothing in this section.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppConfig.subtitleColor,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final r = filtered[i];
                        return _PaRequestCard(
                          r: r,
                          busy: _deletingIds.contains(r.id),
                          onOpen: () async {
                            await context.push<bool>(
                              '${AppRoutes.purchaseAssistantRequests}/${r.id}',
                            );
                            if (context.mounted) {
                              ref.invalidate(purchaseAssistantRequestsProvider);
                            }
                          },
                          onDelete: r.status == 'submitted'
                              ? () => _confirmAndDelete(r)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaRequestCard extends StatelessWidget {
  const _PaRequestCard({
    required this.r,
    required this.onOpen,
    required this.busy,
    this.onDelete,
  });

  final PurchaseAssistantRequestModel r;
  final VoidCallback onOpen;
  final bool busy;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = paStoreLabel(r);
    final title = paProductTitleLine(r);
    final img = r.imageUrls.isNotEmpty
        ? resolveAssetUrl(r.imageUrls.first)
        : null;
    final dateLine = paFormatCreatedAt(r.createdAt);
    final statusColor = paStatusColor(r.status);
    final payHint = r.status == 'awaiting_customer_payment' &&
        r.totalPayable != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onOpen,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        child: Ink(
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            border: Border.all(color: AppConfig.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConfig.radiusMedium),
                      bottomLeft: Radius.circular(AppConfig.radiusMedium),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PurchaseAssistantStoreAvatar(
                          imageUrl: img,
                          labelForInitials: store,
                          size: 72,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      paStatusLabel(r.status),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (r.quantity > 1)
                                    Text(
                                      'Qty ${r.quantity}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppConfig.subtitleColor,
                                      ),
                                    ),
                                  if (dateLine != null)
                                    Text(
                                      dateLine,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppConfig.subtitleColor,
                                      ),
                                    ),
                                ],
                              ),
                              if (payHint) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Amount due: ${paFormatMoney(r.totalPayable, r.currency) ?? '—'}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppConfig.warningOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (onDelete != null)
                          busy
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppConfig.errorRed
                                        .withValues(alpha: 0.85),
                                  ),
                                  onPressed: onDelete,
                                )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: AppConfig.subtitleColor
                                .withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
