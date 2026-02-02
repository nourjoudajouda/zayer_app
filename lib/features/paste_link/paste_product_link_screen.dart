import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/product_import_result.dart';
import 'providers/paste_link_providers.dart';

/// Debounce delay for auto-fetch.
const _debounceMs = 700;

/// States for the paste link flow.
enum _PasteLinkState {
  idle,
  loading,
  success,
  invalid,
  manual,
}

/// Add via Link screen. Route: /paste-link.
class PasteProductLinkScreen extends ConsumerStatefulWidget {
  const PasteProductLinkScreen({super.key});

  @override
  ConsumerState<PasteProductLinkScreen> createState() =>
      _PasteProductLinkScreenState();
}

class _PasteProductLinkScreenState extends ConsumerState<PasteProductLinkScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _nameFocusNode = FocusNode();

  _PasteLinkState _state = _PasteLinkState.idle;
  ProductImportResult? _result;
  String? _invalidError;
  int _quantity = 1;
  int _requestId = 0;
  Timer? _debounceTimer;
  bool _showNormalizedHint = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Fields are enabled when store detected (success) or manual mode.
  bool get _fieldsEnabled =>
      _state == _PasteLinkState.success || _state == _PasteLinkState.manual;

  void _focusNameField() {
    _nameFocusNode.requestFocus();
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: _nameController.text.length),
    );
  }

  void _onUrlChanged() {
    _debounceTimer?.cancel();
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _state = _PasteLinkState.idle;
        _invalidError = null;
        _result = null;
        _showNormalizedHint = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: _debounceMs), () {
      _debounceTimer = null;
      _fetchProduct();
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isNotEmpty) {
      _urlController.text = text.trim();
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlController.text.length),
      );
      // Auto-fetch runs via _onUrlChanged debounce
    }
  }

  Future<void> _fetchProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }

    _requestId++;
    final currentRequestId = _requestId;

    setState(() {
      _state = _PasteLinkState.loading;
      _invalidError = null;
      _result = null;
      _showNormalizedHint = false;
    });

    final repo = ref.read(productLinkImportRepositoryProvider);
    try {
      final result = await repo.fetchByUrl(url);
      if (!mounted) return;
      if (currentRequestId != _requestId) return;

      final canonical = result.canonicalUrl;
      if (canonical != null &&
          canonical.isNotEmpty &&
          canonical != _urlController.text.trim()) {
        _urlController.text = canonical;
        _urlController.selection = TextSelection.fromPosition(
          TextPosition(offset: canonical.length),
        );
        _showNormalizedHint = true;
      }

      setState(() {
        _state = _PasteLinkState.success;
        _result = result;
        _nameController.text = result.name;
        _priceController.text = result.price.toStringAsFixed(2);
      });
    } on InvalidLinkException catch (e) {
      if (!mounted) return;
      if (currentRequestId != _requestId) return;
      setState(() {
        _state = _PasteLinkState.invalid;
        _invalidError = e.message;
      });
    } on UnsupportedLinkException {
      if (!mounted) return;
      if (currentRequestId != _requestId) return;
      setState(() {
        _state = _PasteLinkState.manual;
        _nameController.clear();
        _priceController.clear();
        _showNormalizedHint = false;
      });
    }
  }

  bool get _canAddToCart {
    if (_state == _PasteLinkState.idle ||
        _state == _PasteLinkState.loading ||
        _state == _PasteLinkState.invalid) {
      return false;
    }
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    if (name.isEmpty) {
      return false;
    }
    final price = double.tryParse(priceStr);
    return price != null && price > 0;
  }

  void _addToCart() {
    if (!_canAddToCart) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart (mock)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add via Link'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Paste Product Link',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConfig.textColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Paste the product URL from any international store to add it to your Zayer cart.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildUrlInput(),
              const SizedBox(height: AppSpacing.md),
              if (_state == _PasteLinkState.loading) _buildLoading(),
              if (_state == _PasteLinkState.invalid) _buildInvalidError(),
              if (_state == _PasteLinkState.success || _state == _PasteLinkState.manual)
                _buildStoreCard(),
              if (_state == _PasteLinkState.success || _state == _PasteLinkState.manual)
                _buildProductDetails(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _onUrlSubmitted(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isNotEmpty) {
      _fetchProduct();
    }
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            hintText: 'https://www.example-store.com/item/123',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _pasteFromClipboard,
                child: const Text('PASTE'),
              ),
            ),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: _onUrlSubmitted,
        ),
        if (_showNormalizedHint)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 4),
            child: Text(
              'Normalized link',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConfig.primaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Fetching details...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidError() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _invalidError ?? 'Invalid or unsupported link',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.errorRed,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(AppRoutes.markets),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppConfig.primaryColor,
            ),
            child: const Text('View supported stores'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard() {
    final isManual = _state == _PasteLinkState.manual;
    final storeName = isManual ? 'Unknown Store' : (_result?.storeName ?? '');
    final country = isManual ? '—' : (_result?.country ?? '');
    final isVerified = !isManual;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConfig.borderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: AppConfig.subtitleColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      storeName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppConfig.textColor,
                          ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle,
                          color: AppConfig.successGreen, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified ? 'Official Store Detected' : 'Manual entry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: Text(
              country,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final showManualFields = _state == _PasteLinkState.manual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_state == _PasteLinkState.manual)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppConfig.lightBlueBg,
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              border: Border.all(color: AppConfig.borderColor),
            ),
            child: Text(
              "Couldn't fetch this product automatically. Please enter details manually.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.textColor,
                  ),
            ),
          ),
        // "Edit if needed" helper text (right-aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'Edit if needed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ),
        ),
        // Product Name field with edit icon
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          maxLines: 1,
          enabled: _fieldsEnabled,
          decoration: InputDecoration(
            labelText: 'Product Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _fieldsEnabled
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _focusNameField,
                    tooltip: 'Edit product name',
                    color: AppConfig.subtitleColor,
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              'Quantity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _fieldsEnabled ? AppConfig.textColor : AppConfig.subtitleColor,
                  ),
            ),
            const Spacer(),
            Row(
              children: [
                IconButton.filled(
                  onPressed: _fieldsEnabled
                      ? () => setState(() => _quantity = math.max(1, _quantity - 1))
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppConfig.borderColor,
                    foregroundColor: AppConfig.textColor,
                    disabledBackgroundColor: AppConfig.borderColor.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _fieldsEnabled ? null : AppConfig.subtitleColor,
                        ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _fieldsEnabled
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppConfig.borderColor,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _priceController,
          decoration: _inputDecoration('Price (USD)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: _fieldsEnabled,
        ),
        if (showManualFields) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _imageUrlController,
            decoration: _inputDecoration('Image URL (optional)'),
            keyboardType: TextInputType.url,
            enabled: _fieldsEnabled,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _weightController,
            decoration: _inputDecoration('Weight (optional)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: _fieldsEnabled,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _dimensionsController,
            decoration: _inputDecoration('Dimensions (optional)'),
            keyboardType: TextInputType.text,
            enabled: _fieldsEnabled,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppConfig.lightBlueBg,
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            border: Border.all(color: AppConfig.borderColor),
          ),
          child: Text(
            'Total shipping and customs fees will be calculated and shared for your approval after review.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
          onPressed: _canAddToCart ? _addToCart : null,
          icon: const Icon(Icons.shopping_cart_outlined, size: 22),
          label: const Text('Add to Cart'),
          style: FilledButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppConfig.borderColor,
            disabledForegroundColor: AppConfig.subtitleColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}
