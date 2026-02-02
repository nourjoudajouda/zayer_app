import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markets')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Global markets coming soon',
            style: TextStyle(color: AppConfig.subtitleColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
