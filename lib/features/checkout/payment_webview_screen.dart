import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/platform/webview_supported.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Result returned when the user leaves the payment WebView.
enum PaymentWebViewResult {
  /// User tapped close/back without completing (or from error/unsupported screen).
  closed,
  /// User closed from the payment page; they may have completed payment (refresh order).
  maybeCompleted,
  /// WebView failed to load the checkout URL.
  failedToLoad,
}

/// In-app WebView for Square checkout. Opens [checkoutUrl] and lets the user
/// complete or cancel payment. Close button returns to previous screen with a result.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
  });

  final String checkoutUrl;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _loadError;

  void _popWithResult(PaymentWebViewResult result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  void initState() {
    super.initState();
    if (widget.checkoutUrl.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _popWithResult(PaymentWebViewResult.failedToLoad));
      return;
    }
    if (isWebViewSupported) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() {
                _isLoading = true;
                _loadError = null;
              });
            },
            onPageFinished: (_) {
              if (mounted) setState(() {
                _isLoading = false;
                _loadError = null;
              });
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadError = error.description.isNotEmpty
                      ? error.description
                      : 'Page failed to load';
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.checkoutUrl.trim()));
    } else {
      setState(() {
        _isLoading = false;
        _loadError = 'Payment is not supported on this device.';
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.checkoutUrl.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete payment'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            final result = _loadError != null
                ? PaymentWebViewResult.failedToLoad
                : !isWebViewSupported
                    ? PaymentWebViewResult.closed
                    : PaymentWebViewResult.maybeCompleted;
            Navigator.of(context).pop(result);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!isWebViewSupported) {
      return _buildUnsupportedFallback();
    }
    if (_loadError != null) {
      return _buildErrorBody();
    }
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildUnsupportedFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: AppConfig.subtitleColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Payment is not supported in this app on this device.',
              style: AppTextStyles.titleMedium(AppConfig.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Open the link in your browser to complete payment.',
              style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in browser'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppConfig.errorRed,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _loadError ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium(AppConfig.textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in browser'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
