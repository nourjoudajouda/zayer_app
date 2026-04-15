import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/rounded_card.dart';
import '../checkout/payment_webview_screen.dart';
import '../profile/widgets/badge_pill.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_repository_api.dart';
import 'purchase_assistant_ui.dart';
import 'widgets/purchase_assistant_store_avatar.dart';

class PurchaseAssistantDetailScreen extends StatefulWidget {
  const PurchaseAssistantDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<PurchaseAssistantDetailScreen> createState() =>
      _PurchaseAssistantDetailScreenState();
}

class _PurchaseAssistantDetailScreenState
    extends State<PurchaseAssistantDetailScreen> {
  final _repo = PurchaseAssistantRepositoryApi();
  late Future<PurchaseAssistantRequestModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch(widget.requestId);
  }

  void _reload() {
    setState(() {
      _future = _repo.fetch(widget.requestId);
    });
  }

  Future<void> _openProductUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return;
    }
    if (!await canLaunchUrl(uri)) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pay(PurchaseAssistantRequestModel r) async {
    if (r.convertedOrderId == null || r.convertedOrderId!.isEmpty) return;
    try {
      final url = await _repo.startPayment(r.id);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start payment')),
        );
        return;
      }
      await context.push<PaymentWebViewResult>(
        AppRoutes.paymentWebView,
        extra: url,
      );
      if (!mounted) return;
      _reload();
      context.go('${AppRoutes.orderDetail}/${r.convertedOrderId}');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Payment failed')
          : 'Payment failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _confirmDelete(PurchaseAssistantRequestModel r) async {
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
    try {
      await _repo.deleteRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request removed')),
      );
      context.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Could not delete')
          : 'Could not delete';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<PurchaseAssistantRequestModel>(
      future: _future,
      builder: (context, snap) {
        final r = snap.hasData ? snap.data! : null;
        return Scaffold(
          backgroundColor: AppConfig.backgroundColor,
          appBar: AppBar(
            title: const Text('Request details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (r != null && r.status == 'submitted')
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete request',
                  onPressed: () => _confirmDelete(r),
                ),
            ],
          ),
          body: _buildBody(context, theme, snap),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AsyncSnapshot<PurchaseAssistantRequestModel> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError || !snap.hasData) {
      return Center(child: Text('Error: ${snap.error}'));
    }
    final r = snap.data!;
    final canPay = r.status == 'awaiting_customer_payment' &&
        r.convertedOrderId != null &&
        r.convertedOrderId!.isNotEmpty;
    final store = paStoreLabel(r);
    final title = paProductTitleLine(r);
    final img = r.imageUrls.isNotEmpty
        ? resolveAssetUrl(r.imageUrls.first)
        : null;
    final hasUrl = r.sourceUrl.trim().isNotEmpty;
    final statusColor = paStatusColor(r.status);
    final created = paFormatCreatedAt(r.createdAt);

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PurchaseAssistantStoreAvatar(
                imageUrl: img,
                labelForInitials: store,
                size: 96,
                radius: AppConfig.radiusLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConfig.textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: BadgePill(
                label: paStatusLabel(r.status),
                color: statusColor,
              ),
            ),
            if (created != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                created,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(label: 'Request'),
            const SizedBox(height: AppSpacing.sm),
            RoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Store',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppConfig.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasUrl)
                        IconButton.filledTonal(
                          onPressed: () => _openProductUrl(r.sourceUrl),
                          icon: const Icon(Icons.open_in_new, size: 22),
                          tooltip: 'Open product link',
                        ),
                    ],
                  ),
                  if (r.details != null && r.details!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      r.details!.trim(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Quantity: ${r.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
                  ),
                  if (r.variantDetails != null &&
                      r.variantDetails!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Variant: ${r.variantDetails}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (r.adminProductPrice != null || r.adminServiceFee != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(label: 'Pricing'),
              const SizedBox(height: AppSpacing.sm),
              RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (r.adminProductPrice != null)
                      _PriceRow(
                        label: 'Product price',
                        value:
                            '${r.adminProductPrice} ${r.currency ?? 'USD'}',
                      ),
                    if (r.adminProductPrice != null &&
                        r.adminServiceFee != null)
                      const SizedBox(height: AppSpacing.sm),
                    if (r.adminServiceFee != null)
                      _PriceRow(
                        label: 'Service fee',
                        value:
                            '${r.adminServiceFee} ${r.currency ?? 'USD'}',
                      ),
                  ],
                ),
              ),
            ],
            if (r.adminNotes != null && r.adminNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(label: 'Notes'),
              const SizedBox(height: AppSpacing.sm),
              RoundedCard(
                child: Text(
                  r.adminNotes!.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            if (canPay) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => _pay(r),
                child: const Text('Pay now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppConfig.textColor,
          ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.subtitleColor,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
