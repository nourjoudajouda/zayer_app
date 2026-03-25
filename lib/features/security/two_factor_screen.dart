import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import 'disable_2fa_confirmation.dart';
import 'security_providers.dart';

/// Two-Factor Authentication — status from API (PATCH /api/me/two-factor).
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  bool _busy = false;

  Future<void> _setEnabled(bool enabled) async {
    setState(() => _busy = true);
    try {
      final res = await ApiClient.instance.patch<Map<String, dynamic>>(
        '/api/me/two-factor',
        data: {'enabled': enabled},
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ref.invalidate(securityOverviewProvider);
        final msg = res.data?['message'] as String?;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      } else {
        final m = res.data?['message'] as String? ?? 'Could not update 2FA';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    } on DioException catch (e) {
      if (mounted) {
        final data = e.response?.data;
        final m = data is Map ? data['message'] as String? : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m ?? e.message ?? 'Error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDisable() {
    showDisable2FAConfirmation(
      context,
      onDisable: () => _setEnabled(false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(securityOverviewProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load settings',
                style: TextStyle(color: AppConfig.subtitleColor),
              ),
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppConfig.cardColor,
                    border: Border.all(color: AppConfig.borderColor),
                    borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          color: AppConfig.primaryColor, size: 28),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.twoFactorEnabled ? 'Enabled' : 'Disabled',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: data.twoFactorEnabled
                                        ? AppConfig.successGreen
                                        : AppConfig.subtitleColor,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.twoFactorEnabled
                                  ? 'Your account flag for 2FA is on. Full SMS/app verification can be added later.'
                                  : 'Turn on to require an extra step at login when supported.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppConfig.subtitleColor),
                            ),
                          ],
                        ),
                      ),
                      if (data.twoFactorEnabled)
                        TextButton(
                          onPressed: _busy ? null : _onDisable,
                          child: Text(
                            'Disable',
                            style: TextStyle(
                              color: AppConfig.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: _busy ? null : () => _setEnabled(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enable'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
