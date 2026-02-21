import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';

/// Shows "Disable Two-Factor Authentication?" bottom sheet. onDisable called when user confirms.
void showDisable2FAConfirmation(BuildContext context, {required VoidCallback onDisable}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(ctx).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppConfig.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppConfig.errorRed,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Disable Two-Factor Authentication?',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This will reduce your account security. We strongly recommend keeping 2FA enabled to protect your shipments and wallet.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Keep 2FA Enabled'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDisable();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.errorRed,
                  side: BorderSide(color: AppConfig.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Disable 2FA'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
