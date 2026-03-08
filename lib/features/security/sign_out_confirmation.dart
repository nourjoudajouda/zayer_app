import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';

/// Shows "Sign out from this device?" bottom sheet. On confirm, calls [onSignOut] then navigates to login.
void showSignOutConfirmation(
  BuildContext context, {
  Future<void> Function()? onSignOut,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SignOutConfirmationContent(onSignOut: onSignOut),
  );
}

class _SignOutConfirmationContent extends StatefulWidget {
  const _SignOutConfirmationContent({this.onSignOut});

  final Future<void> Function()? onSignOut;

  @override
  State<_SignOutConfirmationContent> createState() => _SignOutConfirmationContentState();
}

class _SignOutConfirmationContentState extends State<_SignOutConfirmationContent> {
  bool _loading = false;

  Future<void> _confirmSignOut() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onSignOut?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (mounted) context.go(AppRoutes.login);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context;
    return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppConfig.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(Icons.logout, size: 48, color: AppConfig.errorRed),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sign out from this device?',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This device will no longer have access to your account. You can sign back in at any time.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _confirmSignOut,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign Out'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConfig.textColor,
                      side: const BorderSide(color: AppConfig.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
