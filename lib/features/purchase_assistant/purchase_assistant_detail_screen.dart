import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../checkout/payment_webview_screen.dart';
import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_repository_api.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<PurchaseAssistantRequestModel>(
        future: _future,
        builder: (context, snap) {
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
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: const Text('Purchase Assistant'),
                      backgroundColor: AppConfig.primaryColor.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Status: ${r.status}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(r.sourceUrl),
                  if (r.title != null && r.title!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(r.title!, style: Theme.of(context).textTheme.titleSmall),
                  ],
                  if (r.details != null && r.details!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(r.details!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text('Qty: ${r.quantity}'),
                  if (r.variantDetails != null &&
                      r.variantDetails!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Variant: ${r.variantDetails}'),
                  ],
                  if (r.adminProductPrice != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Product price: ${r.adminProductPrice} ${r.currency ?? 'USD'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                  if (r.adminServiceFee != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Service fee: ${r.adminServiceFee} ${r.currency ?? 'USD'}',
                    ),
                  ],
                  if (r.adminNotes != null && r.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Notes: ${r.adminNotes}'),
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
        },
      ),
    );
  }
}
