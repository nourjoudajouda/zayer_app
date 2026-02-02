import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import '../../features/profile/widgets/zayer_tile.dart';
import 'providers/settings_providers.dart';

/// Settings & Preferences screen. Route: /settings.
/// API will plug in: GET/PATCH /api/me/settings for toggles, currency, warehouse.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(effectiveSettingsProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileSectionHeader(title: 'GENERAL'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.language,
                title: 'App Language',
                value: 'Currently: ${settings.languageLabel}',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.attach_money,
                title: 'Display Currency',
                value: '${settings.currencyCode} ${settings.currencySymbol}',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoBox(
                text:
                    'Changing display currency does not convert existing cart or order amounts. Final charge may vary by payment provider.',
              ),
              const SizedBox(height: AppSpacing.md),
              const ProfileSectionHeader(title: 'SHIPPING & LOGISTICS'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.warehouse_outlined,
                title: 'Default Warehouse',
                value: settings.defaultWarehouseLabel,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSwitchTile(
                icon: Icons.inventory_2_outlined,
                title: 'Smart Consolidation',
                value: settings.smartConsolidationEnabled,
                onChanged: (v) =>
                    ref.read(settingsOverridesProvider.notifier).setSmartConsolidation(v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSwitchTile(
                icon: Icons.shield_outlined,
                title: 'Auto-Insurance',
                value: settings.autoInsuranceEnabled,
                onChanged: null,
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.md),
              const ProfileSectionHeader(title: 'COMMUNICATION'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Center',
                value: settings.notificationCenterSummary,
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
              const SizedBox(height: AppSpacing.md),
              const ProfileSectionHeader(title: 'SUPPORT & PRIVACY'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.help_outline,
                title: 'Help & Support Center',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we collect, use and protect your data.',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.login),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppConfig.textColor,
                  side: const BorderSide(color: AppConfig.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: AppSpacing.md),
              _DeleteAccountCard(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'ZAYER LOGISTICS OFFICIAL • Server: ${settings.serverRegion}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        border: Border.all(color: AppConfig.borderColor),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppConfig.subtitleColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? AppConfig.textColor
                        : AppConfig.subtitleColor.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Delete Account',
            style: AppTextStyles.titleMedium(AppConfig.errorRed),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: Text(
              'Delete Account',
              style: TextStyle(
                color: AppConfig.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
