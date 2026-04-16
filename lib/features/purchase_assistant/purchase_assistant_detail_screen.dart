import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/rounded_card.dart';
import '../checkout/payment_webview_screen.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_providers.dart';
import 'purchase_assistant_repository_api.dart';
import 'purchase_assistant_ui.dart';
import 'widgets/purchase_assistant_store_avatar.dart';

/// Full detail for one Purchase Assistant request — separate UX from [OrderDetailScreen].
class PurchaseAssistantDetailScreen extends ConsumerStatefulWidget {
  const PurchaseAssistantDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<PurchaseAssistantDetailScreen> createState() =>
      _PurchaseAssistantDetailScreenState();
}

class _PurchaseAssistantDetailScreenState
    extends ConsumerState<PurchaseAssistantDetailScreen> {
  final _repo = PurchaseAssistantRepositoryApi();
  late Future<PurchaseAssistantRequestModel> _future;
  bool _deleteBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch(widget.requestId);
  }

  void _reload() {
    setState(() {
      _future = _repo.fetch(widget.requestId);
    });
    ref.invalidate(purchaseAssistantRequestsProvider);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated. Status refreshes shortly.')),
      );
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
    setState(() => _deleteBusy = true);
    try {
      await _repo.deleteRequest(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request removed')),
      );
      ref.invalidate(purchaseAssistantRequestsProvider);
      context.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Could not delete')
          : 'Could not delete';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
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
            title: const Text('Purchase Assistant'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            backgroundColor: AppConfig.backgroundColor,
            foregroundColor: AppConfig.textColor,
            elevation: 0,
            actions: [
              if (r != null && r.status == 'submitted')
                _deleteBusy
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
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
    final statusColor = paStatusColor(r.status);
    final explanation = (r.statusExplanation != null &&
            r.statusExplanation!.trim().isNotEmpty)
        ? r.statusExplanation!.trim()
        : null;
    final timeline = paBuildTimeline(
      r.status,
      createdIso: r.createdAt,
      updatedIso: r.updatedAt,
    );

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: const Color(0xFF0369A1),
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Manual pricing & purchase for links outside our standard import flow. '
                      'No shipment tracking here — use Orders only for standard imports after checkout.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConfig.textColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppConfig.textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  paStatusLabel(r.status),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (explanation != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                explanation,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: 'Product / request'),
            const SizedBox(height: AppSpacing.sm),
            RoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 4),
                            Text(
                              store,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.sourceUrl.trim().isNotEmpty)
                        IconButton.filledTonal(
                          onPressed: () => _openProductUrl(r.sourceUrl),
                          icon: const Icon(Icons.open_in_new, size: 22),
                          tooltip: 'Open product link',
                        ),
                    ],
                  ),
                  if (r.imageUrls.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: r.imageUrls.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final src = resolveAssetUrl(r.imageUrls[i]);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: src != null && src.isNotEmpty
                                ? Image.network(
                                    src,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      color: AppConfig.borderColor,
                                    ),
                                  )
                                : Container(
                                    width: 72,
                                    height: 72,
                                    color: AppConfig.borderColor,
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Quantity: ${r.quantity}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (r.variantDetails != null &&
                      r.variantDetails!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Variant: ${r.variantDetails}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: 'Your request'),
            const SizedBox(height: AppSpacing.sm),
            RoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (r.details != null && r.details!.trim().isNotEmpty)
                    Text(
                      r.details!.trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    )
                  else
                    Text(
                      'No extra notes.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                    ),
                  if (r.customerEstimatedPrice != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Your estimate: ${paFormatMoney(r.customerEstimatedPrice, r.currency) ?? '—'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (r.createdAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Submitted: ${paFormatCreatedAt(r.createdAt) ?? r.createdAt}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (r.adminProductPrice != null || r.adminServiceFee != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'Pricing from our team'),
              const SizedBox(height: AppSpacing.sm),
              RoundedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (r.adminProductPrice != null)
                      _PriceRow(
                        label: 'Product price (×${r.quantity})',
                        value: paFormatMoney(
                              r.adminProductPrice! * r.quantity,
                              r.currency,
                            ) ??
                            '—',
                      ),
                    if (r.adminServiceFee != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _PriceRow(
                        label: 'Service fee',
                        value:
                            paFormatMoney(r.adminServiceFee, r.currency) ?? '—',
                      ),
                    ],
                    if (r.totalPayable != null) ...[
                      const Divider(height: AppSpacing.lg),
                      _PriceRow(
                        label: 'Total to pay',
                        value: paFormatMoney(r.totalPayable, r.currency) ?? '—',
                        emphasize: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (r.adminNotes != null && r.adminNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'Notes from our team'),
              const SizedBox(height: AppSpacing.sm),
              RoundedCard(
                child: Text(
                  r.adminNotes!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(title: 'Progress'),
            const SizedBox(height: AppSpacing.sm),
            RoundedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final step in timeline) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            step.current
                                ? Icons.radio_button_checked
                                : step.done
                                    ? Icons.check_circle_outline
                                    : Icons.circle_outlined,
                            size: 22,
                            color: step.current
                                ? const Color(0xFF0EA5E9)
                                : step.done
                                    ? AppConfig.successGreen
                                    : AppConfig.borderColor,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              step.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: step.current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: step.current
                                    ? AppConfig.textColor
                                    : AppConfig.subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (r.updatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Last updated: ${paFormatCreatedAt(r.updatedAt) ?? r.updatedAt}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (canPay) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0369A1),
                ),
                onPressed: () => _pay(r),
                child: Text(
                  r.totalPayable != null
                      ? 'Pay ${paFormatMoney(r.totalPayable, r.currency) ?? 'now'}'
                      : 'Pay now',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppConfig.textColor,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? const Color(0xFF0369A1) : AppConfig.textColor,
              ),
        ),
      ],
    );
  }
}
