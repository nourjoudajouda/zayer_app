import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/profile/widgets/profile_section_header.dart';
import 'models/notification_prefs_model.dart';
import 'providers/notification_prefs_providers.dart';

/// Advanced Notification Control. Matches design: sections, toggles, quiet hours, Save.
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
    _quietFrom = const TimeOfDay(hour: 22, minute: 0);
    _quietTo = const TimeOfDay(hour: 7, minute: 0);
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
        title: Text(
          'Notification Settings',
          style: AppTextStyles.titleLarge(AppConfig.textColor),
        ),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Material(
                color: AppConfig.primaryColor,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                    _NotificationRow(
                      title: 'Push Notifications',
                      subtitle: 'Real-time updates on your device',
                      value: prefs.pushEnabled,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setPush(v),
                    ),
                    const _RowDivider(),
                    _NotificationRow(
                      title: 'Email Notifications',
                      subtitle: 'Detailed summaries and receipts',
                      value: prefs.emailEnabled,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setEmail(v),
                    ),
                    const _RowDivider(),
                    _NotificationRow(
                      title: 'SMS Notifications',
                      subtitle: 'Security and delivery alerts only',
                      value: prefs.smsEnabled,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setSms(v),
                      tag: 'CRITICAL',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ProfileSectionHeader(title: 'ORDER & SHIPMENT'),
                    _NotificationRow(
                      title: 'Live Status Updates',
                      subtitle: 'Tracking changes and delivery milestones',
                      value: prefs.liveStatusUpdates,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setLiveStatusUpdates(v),
                    ),
                    const _RowDivider(),
                    _NotificationRow(
                      title: 'Smart Filter',
                      subtitle: 'Prioritize high-value shipment alerts',
                      value: prefs.smartFilter,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setSmartFilter(v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ProfileSectionHeader(title: 'CUSTOMS & COMPLIANCE'),
                    _ComplianceBanner(),
                    const SizedBox(height: AppSpacing.sm),
                    _NotificationRow(
                      title: 'Duty & Tax Payments',
                      subtitle: 'Mandatory cross-border payment alerts',
                      value: prefs.dutyTaxPayments,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setDutyTaxPayments(v),
                      locked: true,
                    ),
                    const _RowDivider(),
                    _NotificationRow(
                      title: 'Document Requests',
                      subtitle: 'Required customs documentation notices',
                      value: prefs.documentRequests,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setDocumentRequests(v),
                      locked: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ProfileSectionHeader(title: 'PAYMENTS'),
                    _NotificationRow(
                      title: 'Payment Failed',
                      subtitle: 'Critical billing and card issues',
                      value: prefs.paymentFailed,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setPaymentFailed(v),
                      locked: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ProfileSectionHeader(title: 'PROMOTIONS'),
                    _NotificationRow(
                      title: 'Mute All Marketing',
                      subtitle: 'Disable sales, coupons, and newsletters',
                      value: prefs.muteAllMarketing,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setMuteAllMarketing(v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ProfileSectionHeader(title: 'QUIET HOURS'),
                    _NotificationRow(
                      title: 'Scheduled Quiet Hours',
                      value: prefs.quietHoursEnabled,
                      onChanged: (v) => ref
                          .read(notificationPrefsNotifierProvider.notifier)
                          .setQuietHoursEnabled(v),
                    ),
                    if (prefs.quietHoursEnabled) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              label: 'FROM',
                              value: _formatTime(_quietFrom!),
                              onTap: () => _pickTime(context, true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _TimeBox(
                              label: 'TO',
                              value: _formatTime(_quietTo!),
                              onTap: () => _pickTime(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _QuietHoursNote(),
                    ],
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences saved')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConfig.radiusMedium),
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppConfig.borderColor,
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.tag,
    this.locked = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? tag;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConfig.cardColor,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium(AppConfig.textColor),
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.lightBlueBg,
                          borderRadius:
                              BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        child: Text(
                          tag!,
                          style: AppTextStyles.bodySmall(AppConfig.primaryColor)
                              .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.primaryColor),
                        ),
                      ),
                    ],
                    if (locked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: AppConfig.subtitleColor,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: locked ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _ComplianceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 20,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'International regulations require these alerts to remain active for all global shipments.',
              style: AppTextStyles.bodySmall(AppConfig.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
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
              style: AppTextStyles.titleMedium(AppConfig.textColor)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietHoursNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: AppConfig.primaryColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Critical logistics alerts and security codes bypass quiet hours to ensure delivery success.',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
        ),
      ],
    );
  }
}
