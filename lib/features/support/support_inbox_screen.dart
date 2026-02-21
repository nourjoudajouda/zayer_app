import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../profile/widgets/profile_section_header.dart';
import 'models/support_models.dart';
import 'repositories/support_repository.dart';

/// Support Inbox: search, RECENT ORDERS, RESOLVED RECENTLY, FAB to contact support.
class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key});

  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  final SupportRepository _repo = SupportRepository();
  List<SupportInboxItem> _items = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.getInboxItems();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  List<SupportInboxItem> get _recent =>
      _items.where((e) => e.status != 'RESOLVED').toList();
  List<SupportInboxItem> get _resolved =>
      _items.where((e) => e.status == 'RESOLVED').toList();

  List<SupportInboxItem> _filter(List<SupportInboxItem> list) {
    if (_query.trim().isEmpty) return list;
    final q = _query.trim().toLowerCase();
    return list.where((e) {
      return e.id.toLowerCase().contains(q) ||
          (e.orderId?.toLowerCase().contains(q) ?? false) ||
          e.title.toLowerCase().contains(q) ||
          e.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Support Inbox'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search by Ticket ID or Order #',
                  hintStyle: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                  prefixIcon: const Icon(Icons.search, color: AppConfig.subtitleColor),
                  filled: true,
                  fillColor: AppConfig.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    borderSide: const BorderSide(color: AppConfig.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    borderSide: const BorderSide(color: AppConfig.borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        const ProfileSectionHeader(title: 'RECENT ORDERS'),
                        const SizedBox(height: AppSpacing.sm),
                        ..._filter(_recent).map((e) => _InboxTile(
                              item: e,
                              onTap: () {
                                if (e.isTicket) {
                                  context.push(
                                    '${AppRoutes.supportTicket}/${e.id}',
                                  );
                                } else {
                                  context.push(
                                    '${AppRoutes.contactSupport}?orderId=${Uri.encodeComponent(e.orderId ?? e.id)}',
                                  );
                                }
                              },
                            )),
                        if (_filter(_recent).isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No recent orders or tickets.',
                              style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                            ),
                          ),
                        const ProfileSectionHeader(title: 'RESOLVED RECENTLY'),
                        const SizedBox(height: AppSpacing.sm),
                        ..._filter(_resolved).map((e) => _InboxTile(
                              item: e,
                              onTap: () => context.push(
                                '${AppRoutes.supportTicket}/${e.id}',
                              ),
                            )),
                        if (_filter(_resolved).isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              'No resolved tickets.',
                              style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.contactSupport),
        backgroundColor: AppConfig.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item, required this.onTap});

  final SupportInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppConfig.borderColor),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.titleMedium(AppConfig.textColor),
                      ),
                      if (item.subtitle.isNotEmpty)
                        Text(
                          item.subtitle,
                          style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                        ),
                      if (item.orderId != null || item.timeAgo != null)
                        Text(
                          [item.orderId, item.timeAgo]
                              .whereType<String>()
                              .join(' · '),
                          style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Color(item.statusColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                  child: Text(
                    item.status,
                    style: AppTextStyles.bodySmall(Color(item.statusColor)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right, color: AppConfig.subtitleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
