import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'models/address_model.dart';
import 'providers/profile_providers.dart';

/// Add or edit address form. Country/city from backend (dropdowns). Phone + set default. Pops with [true] when saved.
class AddEditAddressScreen extends ConsumerStatefulWidget {
  const AddEditAddressScreen({
    super.key,
    this.addressId,
    this.initialAddressLine,
    this.initialCityId,
    this.initialCityName,
    this.initialCountryId,
    this.initialCountryName,
    this.initialPhone,
    this.initialIsDefault = false,
    this.isEdit = false,
  });

  final String? addressId;
  final String? initialAddressLine;
  final String? initialCityId;
  final String? initialCityName;
  final String? initialCountryId;
  final String? initialCountryName;
  final String? initialPhone;
  final bool initialIsDefault;
  final bool isEdit;

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressLineController;
  late final TextEditingController _phoneController;

  String? _selectedCountryId;
  String? _selectedCityId;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _addressLineController = TextEditingController(text: widget.initialAddressLine ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _selectedCountryId = widget.initialCountryId;
    _selectedCityId = widget.initialCityId;
    _isDefault = widget.initialIsDefault;
  }

  @override
  void dispose() {
    _addressLineController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final countryId = _selectedCountryId;
    final countryMatch = _countries?.where((c) => c.id == countryId).toList();
    final countryName = countryMatch != null && countryMatch.isNotEmpty ? countryMatch.first.name : null;
    final cityId = _selectedCityId;
    final cityMatch = _cities?.where((c) => c.id == cityId).toList();
    final cityName = cityMatch != null && cityMatch.isNotEmpty ? cityMatch.first.name : null;
    if (countryId == null || countryId.isEmpty || countryName == null || countryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select country')));
      return;
    }
    final repo = ref.read(addressRepositoryProvider);
    await repo.saveAddress(
      id: widget.addressId,
      addressLine: _addressLineController.text.trim(),
      countryId: countryId,
      countryName: countryName,
      cityId: cityId?.isEmpty == true ? null : cityId,
      cityName: cityName?.isEmpty == true ? null : cityName,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      isDefault: _isDefault,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  List<CountryOption>? _countries;
  List<CityOption>? _cities;

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = ref.watch(citiesProvider(_selectedCountryId ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Address' : 'Add New Address'),
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
                  controller: _addressLineController,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                    hintText: 'e.g. 123 Main St, Apt 4B',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                countriesAsync.when(
                  data: (list) {
                    _countries = list;
                    return DropdownButtonFormField<String>(
                      value: _selectedCountryId != null && list.any((c) => c.id == _selectedCountryId)
                          ? _selectedCountryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select country'),
                      items: list
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCountryId = v;
                          _selectedCityId = null;
                        });
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    );
                  },
                  loading: () => const InputDecorator(
                    decoration: InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                    child: SizedBox(height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: AppSpacing.md),
                citiesAsync.when(
                  data: (list) {
                    _cities = list;
                    if (list.isEmpty && _selectedCountryId != null) {
                      return const SizedBox.shrink();
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedCityId != null && list.any((c) => c.id == _selectedCityId)
                          ? _selectedCityId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      hint: Text(_selectedCountryId == null ? 'Select country first' : 'Select city'),
                      items: list
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: _selectedCountryId == null ? null : (v) => setState(() => _selectedCityId = v),
                    );
                  },
                  loading: () => const InputDecorator(
                    decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                    child: SizedBox(height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. +1 555 123 4567',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  title: const Text('Set as default address'),
                  subtitle: const Text('Use this address for checkout by default'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeColor: AppConfig.primaryColor,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Address'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
