import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/rounded_card.dart';
import '../profile/widgets/badge_pill.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_repository_api.dart';
import 'purchase_assistant_ui.dart';
import 'widgets/purchase_assistant_store_avatar.dart';

class PurchaseAssistantListScreen extends StatefulWidget {
  const PurchaseAssistantListScreen({super.key});

  @override
  State<PurchaseAssistantListScreen> createState() =>
      _PurchaseAssistantListScreenState();
}

class _PurchaseAssistantListScreenState
    extends State<PurchaseAssistantListScreen> {
  final _repo = PurchaseAssistantRepositoryApi();
  late Future<List<PurchaseAssistantRequestModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.list();
  }

  void _reload() {
    setState(() {
      _future = _repo.list();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Purchase Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.push(AppRoutes.purchaseAssistantSubmit);
              _reload();
            },
            child: const Text('New'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<PurchaseAssistantRequestModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No requests yet')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final r = items[i];
                final store = paStoreLabel(r);
                final title = paProductTitleLine(r);
                final img = r.imageUrls.isNotEmpty
                    ? resolveAssetUrl(r.imageUrls.first)
                    : null;
                final dateLine = paFormatCreatedAt(r.createdAt);
                final statusColor = paStatusColor(r.status);

                return RoundedCard(
                  onTap: () async {
                    await context.push<bool>(
                      '${AppRoutes.purchaseAssistantRequests}/${r.id}',
                    );
                    if (context.mounted) _reload();
                  },
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PurchaseAssistantStoreAvatar(
                        imageUrl: img,
                        labelForInitials: store,
                        size: 64,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
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
                                BadgePill(
                                  label: paStatusLabel(r.status),
                                  color: statusColor,
                                ),
                                if (r.quantity > 1)
                                  Text(
                                    'Qty ${r.quantity}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppConfig.subtitleColor,
                                    ),
                                  ),
                                if (dateLine != null)
                                  Text(
                                    dateLine,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppConfig.subtitleColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppConfig.subtitleColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
