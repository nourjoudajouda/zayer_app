import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import 'models/notification_prefs_model.dart';
import 'providers/notification_prefs_providers.dart';

/// Advanced Notification Control. Route: /notification-settings.
/// API will plug in: GET/PATCH /api/me/notification-preferences for save.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  TimeOfDay? _quietFrom;
  TimeOfDay? _quietTo;

  @override
  void initState() {
    super.initState();
    _quietFrom = TimeOfDay(hour: 22, minute: 0);
    _quietTo = TimeOfDay(hour: 7, minute: 0);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final initial = isFrom ? _quietFrom! : _quietTo!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _quietFrom = picked;
        } else {
          _quietTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationPrefsProvider);
    final overrides = ref.watch(notificationPrefsNotifierProvider);
    final prefs = overrides ?? async.valueOrNull ?? const NotificationPrefsModel();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppConfig.subtitleColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProfileSectionHeader(title: 'GLOBAL CHANNELS'),
                    _NotificationSwitch(
                      title: 'Push Notifications',
                      value: prefs.pushEnabled,
                      onChanged: (v) =>
                          ref.read(notificationPrefsNotifierProvider.notifier).setPush(v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _NotificationSwitch(
                      title: 'Email',
                      value: prefs.emailEnabled,
                      onChanged: (v) =>
                          ref.read(notificationPrefsNotifierProvider.notifier).setEmail(v),
                    ),
                    const ProfileSectionHeader(title: 'ORDER & SHIPMENT'),
                    _NotificationSwitch(
                      title: 'Order Updates',
                      value: prefs.orderUpdates,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setOrderUpdates(v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _NotificationSwitch(
                      title: 'Shipment Updates',
                      value: prefs.shipmentUpdates,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setShipmentUpdates(v),
                    ),
                    const ProfileSectionHeader(title: 'CUSTOMS & COMPLIANCE'),
                    _NotificationSwitch(
                      title: 'Customs & Compliance',
                      value: prefs.customsCompliance,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setCustomsCompliance(v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoBox(
                      text:
                          'We\'ll notify you when your shipment requires documents or customs clearance.',
                    ),
                    const ProfileSectionHeader(title: 'PAYMENTS'),
                    _NotificationSwitch(
                      title: 'Payment Reminders',
                      value: prefs.paymentReminders,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setPaymentReminders(v),
                    ),
                    const ProfileSectionHeader(title: 'PROMOTIONS'),
                    _NotificationSwitch(
                      title: 'Promotions & Offers',
                      value: prefs.promotions,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setPromotions(v),
                    ),
                    const ProfileSectionHeader(title: 'QUIET HOURS'),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: 'From',
                            value: _formatTime(_quietFrom!),
                            onTap: () => _pickTime(context, true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _TimeField(
                            label: 'To',
                            value: _formatTime(_quietTo!),
                            onTap: () => _pickTime(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref.read(notificationPrefsNotifierProvider.notifier).setQuietHours(
                          '${_quietFrom!.hour.toString().padLeft(2, '0')}:${_quietFrom!.minute.toString().padLeft(2, '0')}',
                          '${_quietTo!.hour.toString().padLeft(2, '0')}:${_quietTo!.minute.toString().padLeft(2, '0')}',
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preferences saved')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                    ),
                  ),
                  child: const Text('Save Preferences'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

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
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium(AppConfig.textColor),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          border: Border.all(color: AppConfig.borderColor),
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.titleMedium(AppConfig.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
