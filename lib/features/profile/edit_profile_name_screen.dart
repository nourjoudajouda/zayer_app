import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/success_dialog.dart';
import '../../generated/l10n/app_localizations.dart';
import 'providers/profile_providers.dart';

/// Edit Full Legal Name (and optionally display name). Saves via ProfileRepository and invalidates profile.
class EditProfileNameScreen extends ConsumerStatefulWidget {
  const EditProfileNameScreen({
    super.key,
    this.initialFullLegalName,
    this.initialDisplayName,
  });

  final String? initialFullLegalName;
  final String? initialDisplayName;

  @override
  ConsumerState<EditProfileNameScreen> createState() => _EditProfileNameScreenState();
}

class _EditProfileNameScreenState extends ConsumerState<EditProfileNameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullLegalNameController;
  late final TextEditingController _displayNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullLegalNameController = TextEditingController(text: widget.initialFullLegalName ?? '');
    _displayNameController = TextEditingController(text: widget.initialDisplayName ?? '');
  }

  @override
  void dispose() {
    _fullLegalNameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        fullLegalName: _fullLegalNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        await showSuccessDialog(
          context,
          title: 'Success',
          message: 'Profile updated successfully',
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fullLegalName),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullLegalNameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullLegalName,
                    hintText: 'e.g. John Smith',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'e.g. John',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
