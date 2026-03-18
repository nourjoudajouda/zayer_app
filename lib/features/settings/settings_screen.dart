import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../features/security/sign_out_confirmation.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import '../../features/profile/widgets/zayer_tile.dart';
import 'providers/settings_providers.dart';

void _showLanguageSheet(BuildContext context, WidgetRef ref, String currentCode) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppConfig.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppConfig.radiusMedium)),
    ),
    builder: (ctx) => _LanguageSheet(
      currentCode: currentCode,
      onSelect: (code, label) {
        ref.read(settingsOverridesProvider.notifier).setLanguage(code, label);
        Navigator.of(ctx).pop();
      },
    ),
  );
}

void _showCurrencySheet(BuildContext context, WidgetRef ref, String currentCode) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppConfig.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppConfig.radiusMedium)),
    ),
    builder: (ctx) => _CurrencySheet(
      currentCode: currentCode,
      onSelect: (code, symbol) {
        ref.read(settingsOverridesProvider.notifier).setCurrency(code, symbol);
        Navigator.of(ctx).pop();
      },
    ),
  );
}

/// Settings screen. Route: /settings.
/// API will plug in: GET/PATCH /api/me/settings for toggles, currency, warehouse.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(effectiveSettingsProvider);
    final appName = ref.watch(appDisplayNameProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
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
                onTap: () => _showLanguageSheet(context, ref, settings.languageCode),
              ),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.attach_money,
                title: 'Display Currency',
                value: '${settings.currencyCode} ${settings.currencySymbol}',
                onTap: () => _showCurrencySheet(context, ref, settings.currencyCode),
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
                onTap: () => context.push(AppRoutes.defaultWarehouse),
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
                onChanged: (v) =>
                    ref.read(settingsOverridesProvider.notifier).setAutoInsurance(v),
                enabled: true,
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
                onTap: () => context.push(AppRoutes.supportInbox),
              ),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we collect, use and protect your data.',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => showSignOutConfirmation(context),
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
                '${appName.toUpperCase()} OFFICIAL • Server: ${settings.serverRegion}',
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

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.currentCode, required this.onSelect});

  final String currentCode;
  final void Function(String code, String label) onSelect;

  static const List<Map<String, String>> _options = [
    {'code': 'en', 'label': 'English (US)'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'tr', 'label': 'Türkçe'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'App Language',
              style: AppTextStyles.titleMedium(AppConfig.textColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._options.map((o) {
              final code = o['code']!;
              final label = o['label']!;
              final selected = currentCode == code;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  child: InkWell(
                    onTap: () => onSelect(code, label),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? AppConfig.primaryColor : AppConfig.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: AppTextStyles.bodyLarge(AppConfig.textColor))),
                          if (selected) const Icon(Icons.check_circle, color: AppConfig.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet({required this.currentCode, required this.onSelect});

  final String currentCode;
  final void Function(String code, String symbol) onSelect;

  static const List<Map<String, String>> _options = [
    {'code': 'USD', 'symbol': '\$'},
    {'code': 'EUR', 'symbol': '€'},
    {'code': 'GBP', 'symbol': '£'},
    {'code': 'TRY', 'symbol': '₺'},
    {'code': 'SAR', 'symbol': 'ر.س'},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Display Currency',
              style: AppTextStyles.titleMedium(AppConfig.textColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._options.map((o) {
              final code = o['code']!;
              final symbol = o['symbol']!;
              final selected = currentCode == code;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  child: InkWell(
                    onTap: () => onSelect(code, symbol),
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected ? AppConfig.primaryColor : AppConfig.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Text('$code $symbol', style: AppTextStyles.bodyLarge(AppConfig.textColor)),
                          const Spacer(),
                          if (selected) const Icon(Icons.check_circle, color: AppConfig.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
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
