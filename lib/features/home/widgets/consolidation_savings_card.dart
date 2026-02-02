import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'consolidation_info_sheet.dart';

/// Consolidation savings card. On tap opens info bottom sheet.
/// Content structure ready for API later (title, bullets, button text).
class ConsolidationSavingsCard extends StatelessWidget {
  const ConsolidationSavingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ConsolidationInfoSheet.show(context),
          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: AppConfig.primaryColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.consolidationSavings,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppConfig.textColor,
                            ),
                      ),
                      Text(
                        'Combine items and save up to 80% on shipping cost.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConfig.subtitleColor,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppConfig.subtitleColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
