import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import '../../features/profile/widgets/zayer_tile.dart';
import 'change_password_screen.dart';
import 'active_sessions_screen.dart';
import 'recent_activity_screen.dart';
import 'two_factor_screen.dart';
import 'sign_out_confirmation.dart';

/// Security & Access: password, biometrics, last login, sessions, 2FA, sign out.
class SecurityAccessScreen extends ConsumerStatefulWidget {
  const SecurityAccessScreen({super.key});

  @override
  ConsumerState<SecurityAccessScreen> createState() => _SecurityAccessScreenState();
}

class _SecurityAccessScreenState extends ConsumerState<SecurityAccessScreen> {
  bool _biometricsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Security & Access'),
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
              const ProfileSectionHeader(title: 'PASSWORD MANAGEMENT'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                value: 'Last changed 3 months ago',
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              const ProfileSectionHeader(title: 'BIOMETRICS'),
              const SizedBox(height: AppSpacing.sm),
              _SwitchTile(
                icon: Icons.fingerprint,
                title: 'Face ID / Touch ID',
                value: _biometricsEnabled,
                onChanged: (v) => setState(() => _biometricsEnabled = v),
              ),
              const ProfileSectionHeader(title: 'RECENT ACTIVITY'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.history,
                title: 'Login locations',
                value: 'London, UK • iPhone 15',
                onTap: () => context.push(AppRoutes.recentActivity),
              ),
              const ProfileSectionHeader(title: 'SESSIONS'),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.devices,
                title: 'Manage Active Sessions',
                value: '2 devices currently active',
                onTap: () => context.push(AppRoutes.activeSessions),
              ),
              const SizedBox(height: AppSpacing.sm),
              ZayerTile(
                icon: Icons.shield_outlined,
                title: 'Two-Factor Authentication',
                value: 'Enabled',
                valueColor: AppConfig.successGreen,
                onTap: () => context.push(AppRoutes.twoFactorAuth),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppConfig.primaryColor, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'ENTERPRISE-GRADE SECURITY',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppConfig.textColor,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keeping your account secure helps protect your shipments and wallet balance.',
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Learn more about our safety standards.',
                  style: AppTextStyles.bodySmall(AppConfig.primaryColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => showSignOutConfirmation(
                  context,
                  onSignOut: () => ref.read(authRepositoryProvider).logout(),
                ),
                icon: Icon(Icons.logout, size: 20, color: AppConfig.errorRed),
                label: Text(
                  'Sign out of all sessions',
                  style: TextStyle(color: AppConfig.errorRed, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppConfig.errorRed),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                    color: AppConfig.textColor,
                  ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppConfig.primaryColor),
        ],
      ),
    );
  }
}
