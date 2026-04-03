import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import '../paste_link/models/product_import_result.dart';
import '../paste_link/providers/paste_link_providers.dart';

class ImportProgressScreen extends ConsumerStatefulWidget {
  const ImportProgressScreen({
    super.key,
    required this.url,
  });

  final String url;

  @override
  ConsumerState<ImportProgressScreen> createState() => _ImportProgressScreenState();
}

class _ImportProgressScreenState extends ConsumerState<ImportProgressScreen> {
  int _step = 0;
  Timer? _stepTimer;
  bool _loading = true;
  String? _error;
  ProductImportResult? _result;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _stepTimer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _step = 0;
    });

    // UI-only progress so the user sees movement while waiting for the single API call.
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_step < 3) _step++;
      });
    });

    try {
      final repo = ref.read(productLinkImportRepositoryProvider);
      final r = await repo.fetchByUrl(widget.url);
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() {
        _result = r;
        _loading = false;
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      _stepTimer?.cancel();
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n?.import ?? 'Import'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n?.importProgressTitle ?? 'Preparing your product…',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textColor,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n?.importProgressSubtitle ??
                    'We’ll fetch product details and calculate shipping before confirmation.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_loading) ...[
                _buildSteps(context),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n?.importProgressKeepOpen ?? 'Keep this screen open…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_result != null) ...[
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
                const Spacer(),
              ] else ...[
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
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
                  onPressed: _loading ? null : _start,
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
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (Icons.download_outlined, l10n?.importProgressStepImporting ?? 'Importing product'),
      (Icons.search_outlined, l10n?.importProgressStepReading ?? 'Reading product details'),
      (Icons.local_shipping_outlined, l10n?.importProgressStepShipping ?? 'Calculating shipping'),
      (Icons.checklist_outlined, l10n?.importProgressStepPreparing ?? 'Preparing confirmation'),
    ];

    return Column(
      children: steps.indexed.map((entry) {
        final i = entry.$1;
        final (icon, label) = entry.$2;
        final done = i < _step;
        final active = i == _step;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 20,
                color: done
                    ? AppConfig.successGreen
                    : active
                        ? AppConfig.primaryColor
                        : AppConfig.subtitleColor.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: done
                            ? AppConfig.subtitleColor
                            : active
                                ? AppConfig.textColor
                                : AppConfig.subtitleColor.withValues(alpha: 0.5),
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

