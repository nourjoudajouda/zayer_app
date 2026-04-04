import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import '../paste_link/models/product_import_result.dart';
import '../paste_link/providers/paste_link_providers.dart';

class ImportProgressScreen extends ConsumerStatefulWidget {
  const ImportProgressScreen({
    super.key,
    required this.url,
    this.cachedResult,
    /// When true (Add via Link), header copy matches product fetch; exceptions pop to caller for manual/invalid flows.
    this.pasteLinkMode = false,
  });

  final String url;
  final ProductImportResult? cachedResult;
  final bool pasteLinkMode;

  @override
  ConsumerState<ImportProgressScreen> createState() => _ImportProgressScreenState();
}

class _ImportProgressScreenState extends ConsumerState<ImportProgressScreen> {
  static const int _stepCount = 6;

  int _pulseStep = 0;
  bool _done = false;
  bool _loading = true;
  String? _error;
  ProductImportResult? _result;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    if (widget.cachedResult != null) {
      _runCachedAnimation();
    } else {
      _fetch();
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startPulseTimer() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 520), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_done || !_loading) {
        t.cancel();
        return;
      }
      setState(() {
        if (_pulseStep < _stepCount - 1) {
          _pulseStep++;
        }
      });
    });
  }

  Future<void> _runCachedAnimation() async {
    setState(() {
      _loading = true;
      _pulseStep = 0;
      _done = false;
      _error = null;
      _result = null;
    });
    for (var i = 0; i < _stepCount; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _pulseStep = i);
    }
    if (!mounted) return;
    setState(() {
      _result = widget.cachedResult;
      _loading = false;
      _done = true;
      _pulseStep = _stepCount - 1;
    });
  }

  Future<void> _fetch() async {
    _stepTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _pulseStep = 0;
      _done = false;
    });
    _startPulseTimer();

    try {
      final repo = ref.read(productLinkImportRepositoryProvider);
      final r = await repo.fetchByUrl(widget.url);
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() {
        _result = r;
        _loading = false;
        _done = true;
        _pulseStep = _stepCount - 1;
      });
    } on UnsupportedLinkException catch (e) {
      if (!mounted) return;
      _stepTimer?.cancel();
      Navigator.of(context).pop(e);
    } on InvalidLinkException catch (e) {
      if (!mounted) return;
      _stepTimer?.cancel();
      Navigator.of(context).pop(e);
    } catch (e) {
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  double get _ringValue {
    if (_done) return 1;
    return ((_pulseStep + 1).clamp(1, _stepCount)) / _stepCount;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _stepLabels(l10n);
    final iconUrl = ref.watch(bootstrapConfigProvider).valueOrNull?.appIconUrl;
    final resolvedIcon = resolveAssetUrl(iconUrl, ApiClient.safeBaseUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
                child: Text(
                  widget.pasteLinkMode
                      ? (l10n?.importProgressTitle ?? 'Preparing your product…')
                      : (l10n?.importProgressAddingToCart ?? 'Adding the product to your cart'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _RingPainter(
                              progress: _ringValue,
                              color: AppConfig.primaryColor,
                              trackColor: AppConfig.borderColor.withValues(alpha: 0.55),
                            ),
                          ),
                          _CenterLogo(appIconUrl: resolvedIcon),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_loading && !_done) ...[
                      _buildStepsList(context, steps, mode: _StepListMode.loading),
                      const SizedBox(height: AppSpacing.lg),
                    ] else if (_result != null) ...[
                      _buildStepsList(context, steps, mode: _StepListMode.success),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                          border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppConfig.successGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n?.importProgressReady ?? 'Ready for confirmation',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildStepsList(context, steps, mode: _StepListMode.error),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppConfig.errorRed.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                          border: Border.all(color: AppConfig.errorRed.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.importProgressFailed ?? 'Import failed',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppConfig.errorRed,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n?.importProgressTryAgain ??
                                  'Please check your connection and try again.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppConfig.textColor,
                                    height: 1.35,
                                  ),
                            ),
                            if (_error != null && _error!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppConfig.subtitleColor,
                                      height: 1.25,
                                    ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _result != null
                  ? FilledButton(
                      onPressed: () => Navigator.of(context).pop(_result),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                        ),
                      ),
                      child: Text(l10n?.continueButton ?? 'Continue'),
                    )
                  : FilledButton.icon(
                      onPressed: _loading ? null : _fetch,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n?.retry ?? 'Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<(IconData, String)> _stepLabels(AppLocalizations? l10n) {
    if (widget.pasteLinkMode) {
      return [
        (Icons.link_outlined, l10n?.importProgressStepImporting ?? 'Importing product'),
        (Icons.description_outlined, l10n?.importProgressStepReading ?? 'Reading product details'),
        (
          Icons.straighten_outlined,
          l10n?.importPasteStepDetectingMeasurements ?? 'Detecting measurements',
        ),
        (Icons.local_shipping_outlined, l10n?.importProgressStepShippingCosts ?? 'Calculating shipping costs'),
        (Icons.verified_outlined, l10n?.importProgressStepCustomsCompliance ?? 'Checking customs compliance'),
        (Icons.fact_check_outlined, l10n?.importProgressStepPreparing ?? 'Preparing confirmation'),
      ];
    }
    return [
      (Icons.inventory_2_outlined, l10n?.importProgressStepExtractDetails ?? 'Extracting product details'),
      (Icons.verified_outlined, l10n?.importProgressStepCustomsCompliance ?? 'Checking customs compliance'),
      (Icons.local_shipping_outlined, l10n?.importProgressStepShippingCosts ?? 'Calculating shipping costs'),
      (Icons.account_balance_outlined, l10n?.importProgressStepCustomsDuties ?? 'Calculating customs duties'),
      (Icons.route_outlined, l10n?.importProgressStepShippingMethod ?? 'Identifying shipping method'),
      (Icons.shopping_cart_outlined, l10n?.importProgressStepFinishingCart ?? 'Finishing adding to cart'),
    ];
  }

  Widget _buildStepsList(
    BuildContext context,
    List<(IconData, String)> steps, {
    required _StepListMode mode,
  }) {
    return Column(
      children: steps.indexed.map((entry) {
        final i = entry.$1;
        final (icon, label) = entry.$2;
        final done = mode == _StepListMode.success ||
            (mode == _StepListMode.loading && i < _pulseStep) ||
            (mode == _StepListMode.error && i < _pulseStep);
        final active =
            mode == _StepListMode.loading && !_done && _loading && i == _pulseStep;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StepRow(
            label: label,
            icon: icon,
            done: done,
            active: active,
          ),
        );
      }).toList(),
    );
  }
}

enum _StepListMode { loading, success, error }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.icon,
    required this.done,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    if (done) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 22, color: AppConfig.successGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: baseStyle?.copyWith(
                color: AppConfig.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    if (active) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppConfig.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppConfig.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: baseStyle?.copyWith(
                  color: AppConfig.textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.circle_outlined,
            size: 18,
            color: AppConfig.subtitleColor.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: baseStyle?.copyWith(
              color: AppConfig.subtitleColor.withValues(alpha: 0.55),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterLogo extends StatelessWidget {
  const _CenterLogo({this.appIconUrl});

  final String? appIconUrl;

  @override
  Widget build(BuildContext context) {
    const s = 88.0;
    if (appIconUrl != null && appIconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        child: CachedNetworkImage(
          imageUrl: appIconUrl!,
          width: s,
          height: s,
          fit: BoxFit.cover,
          placeholder: (context, url) => _fallback(s),
          errorWidget: (context, url, e) => _fallback(s),
        ),
      );
    }
    return _fallback(s);
  }

  Widget _fallback(double s) {
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: s * 0.45,
        color: AppConfig.primaryColor,
      ),
    );
  }
}

/// Thin circular progress ring (determinate).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
