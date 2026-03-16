import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'disable_2fa_confirmation.dart';

/// Two-Factor Authentication status. Toggle or "Disable" shows confirmation.
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  bool _enabled = true;

  void _onDisable() {
    showDisable2FAConfirmation(context, onDisable: () {
      if (mounted) {
        setState(() => _enabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-factor authentication disabled')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
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
                    Icon(Icons.shield_outlined, color: AppConfig.primaryColor, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _enabled ? 'Enabled' : 'Disabled',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _enabled ? AppConfig.successGreen : AppConfig.subtitleColor,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _enabled
                                ? 'Your account is protected with 2FA.'
                                : 'Enable 2FA to add an extra layer of security.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status is managed by your account settings when this is supported.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppConfig.subtitleColor,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_enabled)
                      TextButton(
                        onPressed: _onDisable,
                        child: Text(
                          'Disable',
                          style: TextStyle(color: AppConfig.errorRed, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (!_enabled)
                      FilledButton(
                        onPressed: () => setState(() => _enabled = true),
                        style: FilledButton.styleFrom(backgroundColor: AppConfig.primaryColor),
                        child: const Text('Enable'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
