import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Shown when admin enables development_mode. Displays API URL and dev info.
class DevModeScreen extends ConsumerWidget {
  const DevModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(bootstrapConfigProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('وضع التطوير', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.developer_mode, color: Colors.amber.shade700, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'وضع التطوير مفعّل من اللوحة',
                        style: AppTextStyles.titleMedium(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(title: 'رابط الـ API'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: SelectableText(
                  ApiClient.currentBaseUrl ?? config?.apiBaseUrl ?? '—',
                  style: AppTextStyles.bodyMedium(Colors.white70),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'يتم التحكم في رابط الـ API ووضع التطوير من لوحة الإدارة. عند تفعيل وضع التطوير تظهر هذه الشاشة والبانر في التطبيق.',
                style: AppTextStyles.bodySmall(Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bodySmall(Colors.amber.shade200),
    );
  }
}
