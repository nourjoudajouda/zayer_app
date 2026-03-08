import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_spacing.dart';

/// Full-screen overlay shown when the device has no internet connection.
/// Informs the user to reconnect.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConfig.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppConfig.subtitleColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _title(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _message(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 22),
                    label: Text(_retryLabel(context)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _title(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') return 'فشل الاتصال بالإنترنت';
    return 'No internet connection';
  }

  static String _message(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') return 'يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة.';
    return 'Please check your connection and try again.';
  }

  static String _retryLabel(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ar') return 'إعادة المحاولة';
    return 'Retry';
  }
}
