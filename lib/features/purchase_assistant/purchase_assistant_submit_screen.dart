import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/zayer_primary_button.dart';
import 'models/purchase_assistant_prefill.dart';
import 'purchase_assistant_repository_api.dart';

/// Submit a Purchase Assistant request (unsupported / manual Add via Link).
class PurchaseAssistantSubmitScreen extends StatefulWidget {
  const PurchaseAssistantSubmitScreen({super.key, this.prefill});

  final PurchaseAssistantPrefill? prefill;

  @override
  State<PurchaseAssistantSubmitScreen> createState() =>
      _PurchaseAssistantSubmitScreenState();
}

class _PurchaseAssistantSubmitScreenState
    extends State<PurchaseAssistantSubmitScreen> {
  final _repo = PurchaseAssistantRepositoryApi();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _variantCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<File> _images = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _urlCtrl.text = p.sourceUrl;
      if (p.title != null) _titleCtrl.text = p.title!;
      if (p.details != null) _detailsCtrl.text = p.details!;
      _qtyCtrl.text = '${p.quantity}';
      if (p.variantDetails != null) _variantCtrl.text = p.variantDetails!;
      if (p.customerEstimatedPrice != null) {
        _priceCtrl.text = p.customerEstimatedPrice!.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    _variantCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final list = await _picker.pickMultiImage();
    if (list.isEmpty) return;
    setState(() => _images = [..._images, ...list.map((x) => File(x.path))]);
  }

  Future<void> _submit() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product URL')),
      );
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    setState(() => _submitting = true);
    try {
      final est = double.tryParse(_priceCtrl.text.trim());
      await _repo.submit(
        sourceUrl: url,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        details:
            _detailsCtrl.text.trim().isEmpty ? null : _detailsCtrl.text.trim(),
        quantity: qty < 1 ? 1 : qty,
        variantDetails: _variantCtrl.text.trim().isEmpty
            ? null
            : _variantCtrl.text.trim(),
        customerEstimatedPrice: est,
        currency: 'USD',
        images: _images,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request submitted. Our team will review and notify you when payment is ready.',
          ),
        ),
      );
      context.go(AppRoutes.purchaseAssistantRequests);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Could not submit')
          : 'Could not submit';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg,
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: AppConfig.borderColor),
                ),
                child: Text(
                  'This store link is not handled by our automatic import. '
                  'Submit the details below — our team will price it and notify you to pay.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.textColor,
                        height: 1.35,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product URL',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _detailsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Details / notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _variantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color / size / variant (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your estimated price (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Add reference photos (optional)'),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _images
                      .asMap()
                      .entries
                      .map(
                        (e) => InputChip(
                          label: Text('Image ${e.key + 1}'),
                          onDeleted: () => setState(() => _images.removeAt(e.key)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ZayerPrimaryButton(
                label: _submitting ? 'Submitting…' : 'Submit request',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
