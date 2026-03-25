import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import '../../features/profile/widgets/zayer_tile.dart';
import 'sign_out_confirmation.dart';
import 'security_providers.dart';

/// Security & Access: password, biometrics, sessions, 2FA, sign out — backed by API where available.
class SecurityAccessScreen extends ConsumerStatefulWidget {
  const SecurityAccessScreen({super.key});

  @override
  ConsumerState<SecurityAccessScreen> createState() =>
      _SecurityAccessScreenState();
}

class _SecurityAccessScreenState extends ConsumerState<SecurityAccessScreen> {
  bool _biometricsEnabled = false;
  bool _biometricsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final v = await getBiometricsEnabledPreference();
    if (mounted) {
      setState(() {
        _biometricsEnabled = v;
        _biometricsLoaded = true;
      });
    }
  }

  Future<void> _onBiometricsChanged(bool v) async {
    await setBiometricsEnabledPreference(v);
    if (mounted) setState(() => _biometricsEnabled = v);
  }

  Future<void> _signOutAllDevices() async {
    try {
      await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/me/sessions/revoke-all',
        options: Options(
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } catch (_) {
      // Token may already be invalid; still clear local session.
    }
    await ref.read(tokenStoreProvider).clearToken();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(securityOverviewProvider);

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
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Could not load security settings.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(securityOverviewProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (overview) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(securityOverviewProvider);
              await ref.read(securityOverviewProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProfileSectionHeader(title: 'PASSWORD MANAGEMENT'),
                  const SizedBox(height: AppSpacing.sm),
                  ZayerTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    value: overview.changePasswordHint.isNotEmpty
                        ? overview.changePasswordHint
                        : 'Update your password',
                    onTap: () async {
                      await context.push<bool?>(
                        AppRoutes.changePassword,
                      );
                      if (mounted) {
                        ref.invalidate(securityOverviewProvider);
                      }
                    },
                  ),
                  const ProfileSectionHeader(title: 'BIOMETRICS'),
                  const SizedBox(height: AppSpacing.sm),
                  if (_biometricsLoaded)
                    _SwitchTile(
                      icon: Icons.fingerprint,
                      title: 'Face ID / Touch ID',
                      value: _biometricsEnabled,
                      onChanged: _onBiometricsChanged,
                    )
                  else
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  const ProfileSectionHeader(title: 'RECENT ACTIVITY'),
                  const SizedBox(height: AppSpacing.sm),
                  ZayerTile(
                    icon: Icons.history,
                    title: 'Login locations',
                    value: overview.recentActivityPreview.isNotEmpty
                        ? overview.recentActivityPreview
                        : 'Sessions from your devices',
                    onTap: () {
                      context.push(AppRoutes.recentActivity).then((_) {
                        if (mounted) {
                          ref.invalidate(securityOverviewProvider);
                        }
                      });
                    },
                  ),
                  const ProfileSectionHeader(title: 'SESSIONS'),
                  const SizedBox(height: AppSpacing.sm),
                  ZayerTile(
                    icon: Icons.devices,
                    title: 'Manage Active Sessions',
                    value: overview.activeSessionsCount == 1
                        ? '1 device signed in'
                        : '${overview.activeSessionsCount} devices signed in',
                    onTap: () {
                      context.push(AppRoutes.activeSessions).then((_) {
                        if (mounted) {
                          ref.invalidate(securityOverviewProvider);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ZayerTile(
                    icon: Icons.shield_outlined,
                    title: 'Two-Factor Authentication',
                    value: overview.twoFactorEnabled ? 'Enabled' : 'Disabled',
                    valueColor: overview.twoFactorEnabled
                        ? AppConfig.successGreen
                        : AppConfig.subtitleColor,
                    onTap: () {
                      context.push(AppRoutes.twoFactorAuth).then((_) {
                        if (mounted) {
                          ref.invalidate(securityOverviewProvider);
                        }
                      });
                    },
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
                        Icon(Icons.lock_outline,
                            color: AppConfig.primaryColor, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'ENTERPRISE-GRADE SECURITY',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
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
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                    child: Text(
                      'Learn more about our safety standards.',
                      style: AppTextStyles.bodySmall(AppConfig.primaryColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => showSignOutConfirmation(
                      context,
                      onSignOut: () =>
                          ref.read(authRepositoryProvider).logout(),
                    ),
                    icon: Icon(Icons.logout, size: 20, color: AppConfig.errorRed),
                    label: Text(
                      'Sign out of this device',
                      style: TextStyle(
                        color: AppConfig.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppConfig.errorRed),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out everywhere?'),
                          content: const Text(
                            'This will end all sessions on every device. You will need to sign in again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppConfig.errorRed,
                              ),
                              child: const Text('Sign out all'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await _signOutAllDevices();
                      }
                    },
                    icon: Icon(Icons.phonelink_erase_outlined,
                        size: 20, color: AppConfig.errorRed),
                    label: Text(
                      'Sign out of all devices',
                      style: TextStyle(
                        color: AppConfig.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
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
                    color: AppConfig.textColor,
                  ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppConfig.primaryColor,
          ),
        ],
      ),
    );
  }
}
