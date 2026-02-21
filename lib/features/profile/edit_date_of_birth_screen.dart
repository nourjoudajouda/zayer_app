import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import 'providers/profile_providers.dart';

/// Edit date of birth via date picker. Saves via ProfileRepository and invalidates profile.
class EditDateOfBirthScreen extends ConsumerStatefulWidget {
  const EditDateOfBirthScreen({super.key, this.initialDateOfBirth});

  final String? initialDateOfBirth;

  @override
  ConsumerState<EditDateOfBirthScreen> createState() => _EditDateOfBirthScreenState();
}

class _EditDateOfBirthScreenState extends ConsumerState<EditDateOfBirthScreen> {
  static final _displayFormat = DateFormat('MMM d, yyyy');
  DateTime? _selectedDate;

  DateTime _parseInitial() {
    if (widget.initialDateOfBirth == null || widget.initialDateOfBirth!.isEmpty) {
      return DateTime(1990, 1, 1);
    }
    try {
      return _displayFormat.parse(widget.initialDateOfBirth!);
    } catch (_) {
      final iso = DateTime.tryParse(widget.initialDateOfBirth!);
      if (iso != null) return iso;
      return DateTime(1990, 1, 1);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final initial = _selectedDate ?? _parseInitial();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final date = _selectedDate ?? _parseInitial();
    final formatted = _displayFormat.format(date);
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(dateOfBirth: formatted);
    ref.invalidate(userProfileProvider);
    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = _selectedDate ?? _parseInitial();
    final dateStr = _displayFormat.format(date);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dateOfBirth),
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
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
