import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/import/normalize_url.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/zayer_primary_button.dart';
import '../../core/widgets/add_to_cart_success_sheet.dart';
import '../../generated/l10n/app_localizations.dart';
import '../cart/models/cart_item_model.dart';
import '../cart/providers/cart_providers.dart';
import '../cart/repositories/cart_repository.dart';
import '../product_import/import_progress_screen.dart';
import '../purchase_assistant/models/purchase_assistant_prefill.dart';
import 'models/product_import_result.dart';
import 'providers/paste_link_providers.dart';

/// Debounce delay for auto-fetch.
const _debounceMs = 700;

const _shippingEstimateDebounceMs = 650;

/// States for the paste link flow.
enum _PasteLinkState {
  idle,
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
  final _unitPriceController = TextEditingController(); // Price per unit (user edits)
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = []; // For manual mode image uploads

  _PasteLinkState _state = _PasteLinkState.idle;
  ProductImportResult? _result;
  String? _invalidError;
  int _quantity = 1;
  int _requestId = 0;
  Timer? _debounceTimer;
  bool _showNormalizedHint = false;
  bool _isUpdatingFromCanonical = false; // Flag to prevent re-fetch when updating URL
  double? _unitPrice; // Store unit price (from fetch or from _unitPriceController)
  String _weightUnit = 'lb'; // 'lb' = pounds, 'g' = grams
  String _dimensionUnit = 'in'; // 'in' = inches, 'cm' = cm
  /// Selected option index per variation (color, size, etc.)
  final Map<int, int> _selectedVariationIndices = {};
  bool _isAddingToCart = false;
  Timer? _shippingEstimateDebounce;
  bool _shippingEstimateLoading = false;

  double? _shippingPreviewPerUnit;
  String _shippingPreviewCurrency = 'USD';
  bool _shippingPreviewEstimated = false;
  String? _shippingPreviewFootnote;
  bool _shippingPreviewUnavailable = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _weightController.addListener(_scheduleShippingEstimate);
    _lengthController.addListener(_scheduleShippingEstimate);
    _widthController.addListener(_scheduleShippingEstimate);
    _heightController.addListener(_scheduleShippingEstimate);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _shippingEstimateDebounce?.cancel();
    _urlController.removeListener(_onUrlChanged);
    _weightController.removeListener(_scheduleShippingEstimate);
    _lengthController.removeListener(_scheduleShippingEstimate);
    _widthController.removeListener(_scheduleShippingEstimate);
    _heightController.removeListener(_scheduleShippingEstimate);
    _urlController.dispose();
    _nameController.dispose();
    _unitPriceController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Fields are enabled when store detected (success) or manual mode.
  bool get _fieldsEnabled =>
      _state == _PasteLinkState.success || _state == _PasteLinkState.manual;

  void _clearShippingPreview() {
    _shippingEstimateDebounce?.cancel();
    _shippingEstimateLoading = false;
    _shippingPreviewPerUnit = null;
    _shippingPreviewCurrency = 'USD';
    _shippingPreviewEstimated = false;
    _shippingPreviewFootnote = null;
    _shippingPreviewUnavailable = false;
  }

  void _scheduleShippingEstimate() {
    _shippingEstimateDebounce?.cancel();
    if (!_fieldsEnabled) return;
    _shippingEstimateDebounce = Timer(
      const Duration(milliseconds: _shippingEstimateDebounceMs),
      _loadShippingEstimate,
    );
  }

  Future<void> _loadShippingEstimate() async {
    if (!_fieldsEnabled || !mounted) return;
    setState(() {
      _shippingEstimateLoading = true;
      _shippingPreviewUnavailable = false;
      _shippingPreviewFootnote = null;
    });
    final repo = ref.read(cartRepositoryProvider);
    final w = double.tryParse(_weightController.text.trim());
    final l = double.tryParse(_lengthController.text.trim());
    final wi = double.tryParse(_widthController.text.trim());
    final h = double.tryParse(_heightController.text.trim());
    final hasAnyDim = _lengthController.text.trim().isNotEmpty ||
        _widthController.text.trim().isNotEmpty ||
        _heightController.text.trim().isNotEmpty;
    final r = await repo.estimateShipping(
      quantity: _quantity,
      weight: w,
      weightUnit: _weightController.text.trim().isNotEmpty ? _weightUnit : null,
      length: l,
      width: wi,
      height: h,
      dimensionUnit: hasAnyDim ? _dimensionUnit : null,
    );
    if (!mounted) return;
    setState(() {
      _shippingEstimateLoading = false;
      if (!r.available) {
        _shippingPreviewPerUnit = null;
        _shippingPreviewUnavailable = true;
        _shippingPreviewFootnote = r.message;
        return;
      }
      _shippingPreviewUnavailable = false;
      _shippingPreviewPerUnit = r.shippingCost;
      _shippingPreviewCurrency = r.currency;
      _shippingPreviewEstimated = r.estimated;
      final label = r.destinationLabel?.trim();
      final cc = r.destinationCountry?.trim();
      if (label != null && label.isNotEmpty) {
        _shippingPreviewFootnote =
            cc != null && cc.isNotEmpty ? '$label · $cc' : label;
      } else if (cc != null && cc.isNotEmpty) {
        _shippingPreviewFootnote = 'Delivery to $cc';
      } else {
        _shippingPreviewFootnote = null;
      }
    });
  }

  Widget _buildShippingEstimateBanner() {
    if (_shippingEstimateLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          border: Border.all(color: AppConfig.borderColor),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Calculating approximate shipping…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ],
        ),
      );
    }
    if (_shippingPreviewUnavailable) {
      final msg = _shippingPreviewFootnote?.trim();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
        ),
        child: Text(
          msg != null && msg.isNotEmpty
              ? msg
              : 'Sign in and add a default delivery address to see shipping estimates.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConfig.textColor,
              ),
        ),
      );
    }
    final cost = _shippingPreviewPerUnit;
    if (cost == null) return const SizedBox.shrink();
    final label = _shippingPreviewEstimated ? 'Approx. shipping' : 'Shipping estimate';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (qty $_quantity)',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cost.toStringAsFixed(2)} $_shippingPreviewCurrency',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppConfig.primaryColor,
                ),
          ),
          if (_shippingPreviewFootnote != null) ...[
            const SizedBox(height: 6),
            Text(
              _shippingPreviewFootnote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  void _focusNameField() {
    _nameFocusNode.requestFocus();
    _nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: _nameController.text.length),
    );
  }

  void _onUrlChanged() {
    // Don't trigger fetch if we're updating URL from canonical normalization
    if (_isUpdatingFromCanonical) {
      return;
    }

    _debounceTimer?.cancel();
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _state = _PasteLinkState.idle;
        _invalidError = null;
        _result = null;
        _showNormalizedHint = false;
        _clearShippingPreview();
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

  void _applyMeasurementsFromResult(ProductImportResult result) {
    final w = result.weight;
    final wu = (result.weightUnit ?? '').toLowerCase().trim();
    if (w != null && w > 0) {
      if (wu == 'kg' || wu.contains('kilogram')) {
        _weightController.text = (w * 1000).toStringAsFixed(0);
        _weightUnit = 'g';
      } else if (wu.contains('lb') || wu.contains('pound')) {
        _weightController.text = w.toStringAsFixed(2);
        _weightUnit = 'lb';
      } else if (wu == 'g' || wu.contains('gram')) {
        _weightController.text = w.toStringAsFixed(0);
        _weightUnit = 'g';
      } else {
        _weightController.text = w.toStringAsFixed(2);
      }
    }
    final dd = result.dimensionsData;
    if (dd != null && dd.hasAnyDimension) {
      String fmt(double? v) {
        if (v == null || v <= 0) return '';
        return (v == v.roundToDouble()) ? v.round().toString() : v.toStringAsFixed(2);
      }

      if ((dd.length ?? 0) > 0) {
        _lengthController.text = fmt(dd.length);
      } else {
        _lengthController.clear();
      }
      if ((dd.width ?? 0) > 0) {
        _widthController.text = fmt(dd.width);
      } else {
        _widthController.clear();
      }
      if ((dd.height ?? 0) > 0) {
        _heightController.text = fmt(dd.height);
      } else {
        _heightController.clear();
      }
      final u = dd.unit.toLowerCase();
      _dimensionUnit = (u == 'in' || u == 'inch' || u == 'inches') ? 'in' : 'cm';
    }
  }

  void _applyImportResult(ProductImportResult result) {
    _nameController.text = result.name;
    _unitPrice = result.price;
    _unitPriceController.text = result.price.toStringAsFixed(2);
    _selectedVariationIndices.clear();
    _applyMeasurementsFromResult(result);
  }

  Future<void> _fetchProduct() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }

    _requestId++;
    final currentRequestId = _requestId;

    if (!mounted) return;
    final outcome = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => ImportProgressScreen(
          url: url,
          pasteLinkMode: true,
        ),
      ),
    );

    if (!mounted || currentRequestId != _requestId) return;

    setState(() {
      _invalidError = null;
      _showNormalizedHint = false;
      _clearShippingPreview();
    });

    if (outcome is UnsupportedLinkException) {
      final rawUrl = _urlController.text.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push(
          AppRoutes.purchaseAssistantSubmit,
          extra: PurchaseAssistantPrefill(
            sourceUrl: rawUrl.isNotEmpty ? rawUrl : 'https://invalid.local/',
          ),
        );
      });
      return;
    }

    if (outcome is InvalidLinkException) {
      setState(() {
        _state = _PasteLinkState.invalid;
        _invalidError = outcome.message;
        _result = null;
      });
      return;
    }

    if (outcome is ProductImportResult) {
      final result = outcome;
      // Backend sets import_flow from active Featured Stores only; all other domains → Purchase Assistant (no manual cart).
      if (result.importFlow == 'purchase_assistant') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push(
            AppRoutes.purchaseAssistantSubmit,
            extra: PurchaseAssistantPrefill(
              sourceUrl: result.canonicalUrl ?? _urlController.text.trim(),
              title: result.name,
              quantity: _quantity,
              customerEstimatedPrice: result.price > 0 ? result.price : null,
              currency: 'USD',
              imageUrl: result.imageUrl,
            ),
          );
        });
        return;
      }
      final canonical = result.canonicalUrl;
      if (canonical != null &&
          canonical.isNotEmpty &&
          canonical != _urlController.text.trim()) {
        _isUpdatingFromCanonical = true;
        _urlController.text = canonical;
        _urlController.selection = TextSelection.fromPosition(
          TextPosition(offset: canonical.length),
        );
        _showNormalizedHint = true;
        _isUpdatingFromCanonical = false;
      }

      setState(() {
        _state = _PasteLinkState.success;
        _result = result;
        _applyImportResult(result);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleShippingEstimate();
      });
      return;
    }

    setState(() {
      _state = _PasteLinkState.idle;
      _result = null;
    });
  }

  bool get _canAddToCart {
    if (_state == _PasteLinkState.idle || _state == _PasteLinkState.invalid) {
      return false;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    return unitPrice != null && unitPrice > 0;
  }

  bool get _canGoToConfirm {
    return _state == _PasteLinkState.success && _result != null;
  }

  Future<void> _addToCart() async {
    if (!_canAddToCart) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter required details to add this item.'),
            backgroundColor: AppConfig.errorRed,
          ),
        );
      }
      return;
    }

    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    if (unitPrice == null || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter product name'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }

    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter product URL'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
      return;
    }

    // Normalize/canonicalize to avoid excessively long tracking URLs that can break backend storage.
    var productUrl = normalizeProductUrl(rawUrl).canonicalUrl.trim();
    if (productUrl.length > 500) {
      try {
        final u = Uri.parse(productUrl);
        productUrl = u.replace(queryParameters: const {}, fragment: '').toString();
      } catch (_) {}
    }

    // Build variation text from selections (e.g. "Color: Red, Size: M")
    String? variationText;
    if (_result?.variations != null && _result!.variations!.isNotEmpty) {
      variationText = _result!.variations!
          .asMap()
          .entries
          .map((e) {
            final idx = _selectedVariationIndices[e.key] ?? 0;
            final opt = e.value.options.length > idx ? e.value.options[idx] : '';
            return '${e.value.displayLabel}: $opt';
          })
          .join(', ');
    }

    // Build cart item from form data (server uses default saved address when destination omitted).
    final cartItem = CartItem(
      id: generateCartItemId(),
      productUrl: productUrl,
      name: name,
      unitPrice: unitPrice,
      quantity: _quantity,
      currency: 'USD', // Default to USD for manual entry
      imageUrl: _result?.imageUrl, // Use extracted image if available
      storeKey: _result?.storeName != null ? _result!.storeName.toLowerCase().replaceAll(' ', '_') : null,
      storeName: _result?.storeName,
      productId: null,
      country: _result?.country,
      weight: double.tryParse(_weightController.text.trim()),
      weightUnit: _weightController.text.trim().isNotEmpty ? _weightUnit : null,
      length: double.tryParse(_lengthController.text.trim()),
      width: double.tryParse(_widthController.text.trim()),
      height: double.tryParse(_heightController.text.trim()),
      dimensionUnit: (_lengthController.text.trim().isNotEmpty ||
              _widthController.text.trim().isNotEmpty ||
              _heightController.text.trim().isNotEmpty)
          ? _dimensionUnit
          : null,
      source: 'paste_link',
      variationText: variationText,
    );

    if (!mounted) return;
    setState(() => _isAddingToCart = true);
    try {
      final cartNotifier = ref.read(cartItemsProvider.notifier);
      final added = await cartNotifier.addItem(cartItem);
      if (mounted) {
        if (added) {
          final action = await showAddToCartSuccessSheet(
            context,
            message: 'Your item is ready in your cart.',
          );
          if (!mounted) return;
          if (action == AddToCartSuccessAction.goToCart) {
            context.go(AppRoutes.cart);
          } else {
            context.pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This item is already in your cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _friendlyApiMessage(e) ??
          'Could not add to cart right now. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppConfig.errorRed,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add to cart right now. Please try again.'),
          backgroundColor: AppConfig.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  String? _friendlyApiMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          final v = first.first;
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
    }
    if (e.response?.statusCode == 401) return 'Please sign in to continue.';
    if (e.response?.statusCode == 500) return 'Server error. Please try again shortly.';
    return null;
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

  void _clearUrl() {
    _debounceTimer?.cancel();
    _shippingEstimateDebounce?.cancel();
    _isUpdatingFromCanonical = true;
    _urlController.clear();
    _isUpdatingFromCanonical = false;
    setState(() {
      _state = _PasteLinkState.idle;
      _invalidError = null;
      _result = null;
      _showNormalizedHint = false;
      _unitPrice = null;
      _quantity = 1;
      _nameController.clear();
      _unitPriceController.clear();
      _weightController.clear();
      _lengthController.clear();
      _widthController.clear();
      _heightController.clear();
      _selectedImages.clear();
      _selectedVariationIndices.clear();
      _clearShippingPreview();
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: AppConfig.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages = [image];
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppConfig.errorRed,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _updateTotalPrice() {
    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    if (unitPrice != null) {
      _unitPrice = unitPrice;
    }
    setState(() {}); // Refresh total display
  }

  double? get _displayTotalPrice {
    final unitPrice = _unitPrice ?? double.tryParse(_unitPriceController.text.trim());
    if (unitPrice == null) return null;
    return unitPrice * _quantity;
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
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _urlController,
              builder: (context, value, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearUrl,
                        tooltip: 'Clear',
                        color: AppConfig.subtitleColor,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _pasteFromClipboard,
                        child: const Text('PASTE'),
                      ),
                    ),
                  ],
                );
              },
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
    final hasImage = _result?.imageUrl != null && _result!.imageUrl!.isNotEmpty;

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
        // Product Image - Show extracted image in success mode
        if (hasImage && _state == _PasteLinkState.success)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            height: 200,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
              border: Border.all(color: AppConfig.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
              child: Builder(
                builder: (context) {
                  final url = resolveAssetUrl(_result!.imageUrl, ApiClient.safeBaseUrl);
                  if (url == null || url.isEmpty) {
                    return Center(
                      child: Icon(Icons.image_not_supported, color: AppConfig.subtitleColor, size: 48),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConfig.primaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: AppConfig.subtitleColor,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConfig.subtitleColor,
                            ),
                      ),
                    ],
                  ),
                ),
              );
                },
              ),
            ),
          ),
        // Variations (color, size, etc.) when API returns them
        if (_state == _PasteLinkState.success &&
            _result?.variations != null &&
            _result!.variations!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
              border: Border.all(color: AppConfig.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_result!.variations!.length, (i) {
                  final v = _result!.variations![i];
                  final selectedIndex = _selectedVariationIndices[i] ?? 0;
                  final safeIndex = selectedIndex.clamp(0, v.options.isNotEmpty ? v.options.length - 1 : 0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.displayLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppConfig.textColor,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(v.options.length, (j) {
                            final opt = v.options[j];
                            final isSelected = safeIndex == j;
                            final price = v.priceAt(j);
                            final label = price != null && price > 0
                                ? '$opt (\$${price.toStringAsFixed(2)})'
                                : opt;
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() {
                                  _selectedVariationIndices[i] = j;
                                  if (price != null && price > 0) {
                                    _unitPrice = price;
                                    _unitPriceController.text = price.toStringAsFixed(2);
                                  }
                                });
                                _scheduleShippingEstimate();
                              },
                              selectedColor: AppConfig.primaryColor.withValues(alpha: 0.3),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // Image Upload Section - Only in manual mode - Only in manual mode
        if (showManualFields) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Product Images (optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fieldsEnabled ? _pickImages : null,
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text('Pick from Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fieldsEnabled ? _pickImageFromCamera : null,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      border: Border.all(color: AppConfig.borderColor),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
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
                      ? () {
                          setState(() {
                            _quantity = math.max(1, _quantity - 1);
                            _updateTotalPrice();
                          });
                          _scheduleShippingEstimate();
                        }
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
                      ? () {
                          setState(() {
                            _quantity++;
                            _updateTotalPrice();
                          });
                          _scheduleShippingEstimate();
                        }
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
          controller: _unitPriceController,
          decoration: _inputDecoration('Unit Price (USD)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: _state == _PasteLinkState.manual,
          onChanged: (_) => _updateTotalPrice(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Total price (read-only display)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppConfig.borderColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            border: Border.all(color: AppConfig.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (USD)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              Text(
                _displayTotalPrice != null
                    ? _displayTotalPrice!.toStringAsFixed(2)
                    : '—',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConfig.textColor,
                    ),
              ),
            ],
          ),
        ),
        if (_fieldsEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          _buildShippingEstimateBanner(),
        ],
        // Weight - optional, with unit (lb / g)
        const SizedBox(height: AppSpacing.md),
        Text(
          'Weight (optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _fieldsEnabled ? AppConfig.textColor : AppConfig.subtitleColor,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _weightController,
                decoration: _inputDecoration('Value'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: _fieldsEnabled,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _weightUnit,
                decoration: _inputDecoration('Unit'),
                items: const [
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                ],
                onChanged: _fieldsEnabled
                    ? (value) {
                        if (value != null) {
                          setState(() => _weightUnit = value);
                          _scheduleShippingEstimate();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
        // Dimensions - 3 fields (L x W x H) with unit (in / cm)
        const SizedBox(height: AppSpacing.md),
        Text(
          'Dimensions (optional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _fieldsEnabled ? AppConfig.textColor : AppConfig.subtitleColor,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lengthController,
                decoration: _inputDecoration('L'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: _fieldsEnabled,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: TextField(
                controller: _widthController,
                decoration: _inputDecoration('W'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: _fieldsEnabled,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: TextField(
                controller: _heightController,
                decoration: _inputDecoration('H'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: _fieldsEnabled,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 72,
              child: DropdownButtonFormField<String>(
                initialValue: _dimensionUnit,
                decoration: _inputDecoration('Unit'),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('in')),
                  DropdownMenuItem(value: 'cm', child: Text('cm')),
                ],
                onChanged: _fieldsEnabled
                    ? (value) {
                        if (value != null) {
                          setState(() => _dimensionUnit = value);
                          _scheduleShippingEstimate();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppConfig.lightBlueBg,
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            border: Border.all(color: AppConfig.borderColor),
          ),
          child: Text(
            'Shipping estimate uses your default saved address on the server. Final total may change if admin adjusts weight or fees.',
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
    final loading = _isAddingToCart;
    final showHint = !loading && _fieldsEnabled && !_canAddToCart;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHint)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Enter a name and unit price to continue.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ZayerPrimaryButton(
              label: _canGoToConfirm
                  ? (l10n?.reviewAndAdd ?? 'Review & Add')
                  : (loading ? 'Adding...' : 'Add to Cart'),
              onPressed: (!loading && _canGoToConfirm)
                  ? () {
                      final r = _result;
                      if (r == null) return;
                      context.push(
                        '${AppRoutes.confirmProduct}?url=${Uri.encodeComponent(r.canonicalUrl ?? _urlController.text.trim())}',
                        extra: r,
                      );
                    }
                  : ((!loading && _canAddToCart) ? _addToCart : null),
              icon: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined, size: 22, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
