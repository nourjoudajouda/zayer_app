import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';

/// Reusable bottom sheet explaining consolidation savings.
/// Content structure ready for API later (title, description bullets, button text).
class ConsolidationInfoSheet extends StatelessWidget {
  const ConsolidationInfoSheet({super.key});

  /// Show the sheet. Replace content with API data later.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConsolidationInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with API-fetched content (title, bullets, buttonText, learnMoreUrl)
    const title = 'Consolidation Savings';
    const bullets = [
      'Combine items from different stores into one shipment.',
      'Save up to 70% on international shipping fees.',
      'Faster delivery with consolidated routing.',
    ];
    const buttonText = 'Got it';
    const learnMoreText = 'Learn more';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConfig.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textColor,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppConfig.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppConfig.textColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(learnMoreText),
            ),
          ),
        ],
      ),
    );
  }
}
