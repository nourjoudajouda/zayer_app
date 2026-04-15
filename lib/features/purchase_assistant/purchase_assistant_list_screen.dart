import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_repository_api.dart';

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
    return Scaffold(
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
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final r = items[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      r.title?.isNotEmpty == true ? r.title! : r.sourceUrl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${r.status}\n${r.sourceUrl}',
                      maxLines: 3,
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push(
                        '${AppRoutes.purchaseAssistantRequests}/${r.id}',
                      );
                      _reload();
                    },
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
