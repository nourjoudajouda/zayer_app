import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';

/// Placeholder screen for features not yet implemented.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? l10n.comingSoon),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppConfig.subtitleColor),
            const SizedBox(height: 24),
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppConfig.textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is coming soon.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
