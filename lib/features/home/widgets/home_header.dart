import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Top header: avatar, greeting, notification bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    this.onProfileTap,
    this.onNotificationTap,
  });

  final String greeting;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfileTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppConfig.borderColor,
              child: const Icon(Icons.person, color: AppConfig.subtitleColor),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helloUser(greeting),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConfig.textColor,
                          ),
                    ),
                    Text(
                      l10n.welcomeBackCaps,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationTap,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.notifications_outlined, size: 22, color: AppConfig.textColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
