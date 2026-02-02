import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Search field + filter button row.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchStoresOrItems,
              prefixIcon: const Icon(Icons.search, size: 22),
              filled: true,
              fillColor: AppConfig.borderColor.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: AppConfig.primaryColor,
          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
