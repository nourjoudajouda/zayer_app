import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import 'models/user_profile_model.dart';
import 'providers/profile_providers.dart';
import 'widgets/action_card.dart';
import 'widgets/badge_pill.dart';
import 'widgets/profile_section_header.dart';
import 'widgets/zayer_tile.dart';

/// Profile & Compliance screen. Route: /account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _appVersion = 'Zayer v1.0.0'; // TODO: Use package_info_plus when available

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final complianceAsync = ref.watch(complianceStatusProvider);
    final avatarState = ref.watch(avatarImageProvider);
    final avatarFile = avatarState.$1;
    final avatarVersion = avatarState.$2;

    return Directionality(
      textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Profile & Compliance'),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language switch coming soon')),
                );
              },
              child: Text(locale == AppLocale.en ? 'EN' : 'AR'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (profile) => complianceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (compliance) => _ProfileContent(
                profile: profile,
                compliance: compliance,
                avatarFile: avatarFile,
                avatarVersion: avatarVersion,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.profile,
    required this.compliance,
    this.avatarFile,
    this.avatarVersion = 0,
  });

  final UserProfile profile;
  final ComplianceStatus compliance;
  final File? avatarFile;
  final int avatarVersion;

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Choose Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConfig.textColor,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final x = await picker.pickImage(source: ImageSource.gallery);
                if (x != null && context.mounted) {
                  final file = File(x.path);
                  final prev = ref.read(avatarImageProvider);
                  ref.read(avatarImageProvider.notifier).state = (file, prev.$2 + 1);
                  await ref.read(profileRepositoryProvider).uploadAvatar(file);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo saved')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final x = await picker.pickImage(source: ImageSource.camera);
                if (x != null && context.mounted) {
                  final file = File(x.path);
                  final prev = ref.read(avatarImageProvider);
                  ref.read(avatarImageProvider.notifier).state = (file, prev.$2 + 1);
                  await ref.read(profileRepositoryProvider).uploadAvatar(file);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo saved')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            profile: profile,
            avatarFile: avatarFile,
            avatarVersion: avatarVersion,
            onCameraTap: () => _showAvatarPicker(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
          _IdentityCard(
            compliance: compliance,
            onUploadTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload coming soon')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {},
            child: Text(l10n.whyIsThisRequired),
          ),
          ProfileSectionHeader(title: 'PERSONAL INFO'),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.person_outline,
            title: l10n.fullLegalName,
            value: profile.fullLegalName,
            onTap: () => context.push(
              AppRoutes.editProfileName,
              extra: <String, dynamic>{
                'fullLegalName': profile.fullLegalName,
                'displayName': profile.displayName,
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.cake_outlined,
            title: l10n.dateOfBirth,
            value: profile.dateOfBirth ?? '—',
            onTap: () => context.push(
              AppRoutes.editDateOfBirth,
              extra: <String, dynamic>{'dateOfBirth': profile.dateOfBirth},
            ),
          ),
          ProfileSectionHeader(title: 'PRIMARY SHIPPING ADDRESS'),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.location_on_outlined,
            title: profile.primaryAddressCountry ?? l10n.primaryShippingAddress,
            subtitle: profile.primaryAddress,
            onTap: () => context.push(AppRoutes.myAddresses),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppConfig.lightBlueBg,
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            ),
            child: Text(
              'Address is locked during active shipments. Contact support to update.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.primaryColor,
                  ),
            ),
          ),
          ProfileSectionHeader(title: 'SECURITY & ACCESS'),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.security_outlined,
            title: 'Security Settings',
            subtitle: 'Password, biometrics & login activity',
            onTap: () => context.push(AppRoutes.security),
          ),
          ProfileSectionHeader(title: 'PREFERENCES'),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.favorite_border,
            title: 'Favorites',
            onTap: () => context.push(AppRoutes.favorites),
          ),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.payment_outlined,
            title: l10n.paymentMethods,
            onTap: () => context.push(AppRoutes.paymentMethods),
          ),
          const SizedBox(height: AppSpacing.sm),
          ZayerTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Top up balance',
            onTap: () => context.push(AppRoutes.topUpWallet),
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
            child: Text(l10n.logout),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
            label: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Colors.red.shade700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.red.shade400),
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              ProfileScreen._appVersion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    this.avatarFile,
    this.avatarVersion = 0,
    required this.onCameraTap,
  });

  final UserProfile profile;
  final File? avatarFile;
  final int avatarVersion;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                key: ValueKey<int>(avatarVersion),
                radius: 55,
                backgroundColor: AppConfig.borderColor,
                backgroundImage: avatarFile != null ? FileImage(avatarFile!) : null,
                child: avatarFile == null
                    ? const Icon(Icons.person, size: 56, color: AppConfig.subtitleColor)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (profile.verified)
            BadgePill(
              label: l10n.verifiedForInternational,
              icon: Icons.check,
              color: AppConfig.successGreen,
            ),
          if (profile.lastVerifiedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last verified: ${profile.lastVerifiedAt}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.compliance,
    required this.onUploadTap,
  });

  final ComplianceStatus compliance;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ActionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, color: AppConfig.primaryColor, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.identityVerification,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
              ),
              if (compliance.actionRequired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Text(
                        l10n.actionRequired,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (compliance.expiryDate != null) ...[
            const SizedBox(height: 8),
            Text(
              compliance.expiryDate!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          if (compliance.description != null)
            Text(
              compliance.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onUploadTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              ),
            ),
            child: Text(l10n.uploadNewGovernmentId),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ActionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (profile.primaryAddressCountry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    profile.primaryAddressCountry!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                  ),
                ),
              if (profile.primaryAddressCountry != null) const SizedBox(width: 8),
              if (profile.isDefault)
                BadgePill(
                  label: l10n.defaultBadge,
                  icon: Icons.lock,
                  color: AppConfig.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.primaryAddress,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.textColor,
                ),
          ),
        ],
      ),
    );
  }
}
