import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Privacy Policy screen. Shows summary and link to full policy (in-app or browser).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _policyUrl = 'https://zayer.com/privacy';

  Future<void> _openFullPolicy(BuildContext context) async {
    final uri = Uri.parse(_policyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How we collect, use and protect your data',
                style: AppTextStyles.titleMedium(AppConfig.textColor),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Zayer collects information you provide when you register, place orders, or contact support. '
                'We use this to process your shipments, communicate with you, and improve our services. '
                'We do not sell your personal data to third parties. '
                'Payment data is handled by secure providers and we do not store full card details.',
                style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'We may share data with logistics partners to fulfill deliveries, and with legal authorities when required by law. '
                'You can request access to or deletion of your data by contacting support.',
                style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _openFullPolicy(context),
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('View full Privacy Policy online'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.primaryColor,
                  side: const BorderSide(color: AppConfig.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
