import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../ui/zayer_primary_button.dart';

/// Reusable empty-state layout: illustration, title, subtitle, primary/secondary CTAs.
/// Use for Favorites, Notifications, Orders, Cart empty screens.
class EmptyStateScaffold extends StatelessWidget {
  const EmptyStateScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.appBarTitle,
    this.showBackButton = false,
    this.appBarActions,
    this.illustration,
    this.primaryButtonLabel,
    this.primaryButtonIcon,
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    this.onSecondaryPressed,
  });

  final String title;
  final String subtitle;
  final String? appBarTitle;
  final bool showBackButton;
  final List<Widget>? appBarActions;
  final Widget? illustration;
  final String? primaryButtonLabel;
  final Widget? primaryButtonIcon;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonLabel;
  final Widget? secondaryButtonIcon;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: appBarTitle != null ? Text(appBarTitle!) : null,
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: appBarActions,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              if (illustration != null) illustration!,
              if (illustration != null) const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall(AppConfig.textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (primaryButtonLabel != null && onPrimaryPressed != null)
                ZayerPrimaryButton(
                  label: primaryButtonLabel!,
                  onPressed: onPrimaryPressed,
                  icon: primaryButtonIcon,
                ),
              if (secondaryButtonLabel != null && onSecondaryPressed != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSecondaryPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                      side: const BorderSide(color: AppConfig.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                      ),
                    ),
                    child: secondaryButtonIcon != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              secondaryButtonIcon!,
                              const SizedBox(width: 8),
                              Text(secondaryButtonLabel!),
                            ],
                          )
                        : Text(secondaryButtonLabel!),
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
