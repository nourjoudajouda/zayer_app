import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Success screen after submitting a support request: ticket number, estimated response, actions.
class SupportRequestSubmittedScreen extends StatelessWidget {
  const SupportRequestSubmittedScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Support Request Submitted'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Icon(
                Icons.headset_mic,
                size: 64,
                color: AppConfig.successGreen,
              ),
              const SizedBox(height: AppSpacing.sm),
              Icon(
                Icons.check_circle,
                size: 32,
                color: AppConfig.successGreen,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Support Request Submitted',
                style: AppTextStyles.headlineSmall(AppConfig.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your request has been received successfully.',
                style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppConfig.lightBlueBg.withValues(alpha: 0.5),
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Column(
                  children: [
                    Text(
                      'TICKET NUMBER',
                      style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ticketId,
                      style: AppTextStyles.titleLarge(AppConfig.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppConfig.borderColor),
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppConfig.subtitleColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated response: 24-48 hours',
                            style: AppTextStyles.titleMedium(AppConfig.textColor),
                          ),
                          Text(
                            'You\'ll be notified once our support team responds.',
                            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                  child: const Text('Back to Order'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.supportInbox),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConfig.primaryColor,
                    side: const BorderSide(color: AppConfig.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    ),
                  ),
                  child: const Text('View My Tickets'),
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
