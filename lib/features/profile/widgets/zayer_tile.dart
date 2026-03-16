import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';

/// Reusable profile tile: icon + title + optional value/subtitle + chevron.
class ZayerTile extends StatelessWidget {
  const ZayerTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.valueColor,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppConfig.borderColor),
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppConfig.subtitleColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasValue)
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppConfig.subtitleColor,
                            ),
                      ),
                    if (hasValue && value != null)
                      Text(
                        value!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: valueColor ?? AppConfig.textColor,
                            ),
                      ),
                    if (!hasValue) ...[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppConfig.textColor,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConfig.subtitleColor,
                              ),
                        ),
                    ],
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppConfig.subtitleColor),
            ],
          ),
        ),
      ),
    );
  }
}
