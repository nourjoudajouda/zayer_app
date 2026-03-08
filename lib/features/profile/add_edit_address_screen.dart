import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'models/address_model.dart';
import 'providers/profile_providers.dart';

/// Add or edit address form. Two steps: Location (verified country/city, area, street, building), then Details (nickname, type, map). Pops with [true] when saved.
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
    this.initialNickname,
    this.initialAddressTypeIndex,
    this.initialAreaDistrict,
    this.initialStreetAddress,
    this.initialBuildingVillaSuite,
    this.initialLat,
    this.initialLng,
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
  final String? initialNickname;
  final int? initialAddressTypeIndex;
  final String? initialAreaDistrict;
  final String? initialStreetAddress;
  final String? initialBuildingVillaSuite;
  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _areaDistrictController;
  late final TextEditingController _streetAddressController;
  late final TextEditingController _buildingController;
  late final TextEditingController _nicknameController;

  int _currentStep = 0;
  String? _selectedCountryId;
  String? _selectedCityId;
  bool _isDefault = false;
  AddressType _addressType = AddressType.home;
  bool _streetNeedsReview = false;
  double? _lat;
  double? _lng;
  GoogleMapController? _mapController;
  bool _isSaving = false;
  static const LatLng _defaultCenter = LatLng(25.0760, 55.3093); // Dubai

  @override
  void initState() {
    super.initState();
    _areaDistrictController = TextEditingController(text: widget.initialAreaDistrict ?? '');
    _streetAddressController = TextEditingController(text: widget.initialStreetAddress ?? widget.initialAddressLine ?? '');
    _buildingController = TextEditingController(text: widget.initialBuildingVillaSuite ?? '');
    _nicknameController = TextEditingController(text: widget.initialNickname ?? '');
    _selectedCountryId = widget.initialCountryId ?? 'ae';
    _selectedCityId = widget.initialCityId ?? 'dxb';
    _isDefault = widget.initialIsDefault;
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    if (widget.initialAddressTypeIndex != null && widget.initialAddressTypeIndex! < AddressType.values.length) {
      _addressType = AddressType.values[widget.initialAddressTypeIndex!];
    }
  }

  @override
  void dispose() {
    _areaDistrictController.dispose();
    _streetAddressController.dispose();
    _buildingController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String get _countryName {
    final list = _countries;
    if (list != null && _selectedCountryId != null) {
      final c = list.where((e) => e.id == _selectedCountryId).firstOrNull;
      if (c != null) return c.name;
    }
    return _selectedCountryId ?? '';
  }

  String get _cityName {
    final list = _cities;
    if (list != null && _selectedCityId != null) {
      final c = list.where((e) => e.id == _selectedCityId).firstOrNull;
      if (c != null) return c.name;
    }
    return _selectedCityId ?? '';
  }

  LatLng get _markerPosition => _lat != null && _lng != null ? LatLng(_lat!, _lng!) : _defaultCenter;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final countryId = _selectedCountryId ?? 'ae';
      final countryName = _countryName;
      final cityId = _selectedCityId;
      final cityName = _cityName;
      final street = _streetAddressController.text.trim();
      final building = _buildingController.text.trim();
      final area = _areaDistrictController.text.trim();
      final addressLine = [street, building.isNotEmpty ? building : null, area, cityName, countryName]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
      final repo = ref.read(addressRepositoryProvider);
      await repo.saveAddress(
        id: widget.addressId,
        addressLine: addressLine.isEmpty ? '${_cityName}, $countryName' : addressLine,
        countryId: countryId,
        countryName: countryName,
        cityId: cityId?.isEmpty == true ? null : cityId,
        cityName: cityName.isEmpty ? null : cityName,
        phone: widget.initialPhone?.trim().isEmpty == true ? null : widget.initialPhone,
        isDefault: _isDefault,
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        addressType: _addressType,
        areaDistrict: _areaDistrictController.text.trim().isEmpty ? null : _areaDistrictController.text.trim(),
        streetAddress: street.isEmpty ? null : street,
        buildingVillaSuite: building.isEmpty ? null : building,
        isVerified: true,
        isResidential: _addressType == AddressType.home,
        lat: _lat,
        lng: _lng,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<CountryOption>? _countries;
  List<CityOption>? _cities;

  @override
  Widget build(BuildContext context) {
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = ref.watch(citiesProvider(_selectedCountryId ?? ''));

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Address' : 'Add New Address'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // Progress: 1 LOCATION, 2 DETAILS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepIndicator(step: 1, label: 'LOCATION', isActive: _currentStep == 0, isDone: _currentStep > 0),
                    const SizedBox(width: 24),
                    _StepIndicator(step: 2, label: 'DETAILS', isActive: _currentStep == 1, isDone: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // International Compliance Notice
                _ComplianceBanner(),
                const SizedBox(height: AppSpacing.lg),
                if (_currentStep == 0) _buildStep1Location(countriesAsync, citiesAsync),
                if (_currentStep == 1) _buildStep2Details(),
                const SizedBox(height: AppSpacing.xl),
                if (_currentStep == 0)
                  OutlinedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) setState(() => _currentStep = 1);
                    },
                    child: const Text('Continue to Details'),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    child: const Text('Back to Location'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(_isSaving ? 'Saving...' : 'Save Address'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'SECURE 256-BIT ENCRYPTED DATA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.subtitleColor),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Location(AsyncValue<List<CountryOption>> countriesAsync, AsyncValue<List<CityOption>> citiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 1: Verified Location',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppConfig.textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Country
        Text('Country', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor)),
        const SizedBox(height: 6),
        countriesAsync.when(
          data: (list) {
            _countries = list;
            final selected = list.where((c) => c.id == _selectedCountryId).firstOrNull;
            return DropdownSearch<CountryOption>(
              selectedItem: selected,
              items: (filter, loadProps) {
                if (list.isEmpty) return [];
                if (filter.isEmpty) return list;
                final f = filter.toLowerCase();
                return list.where((c) => c.name.toLowerCase().contains(f)).toList();
              },
              itemAsString: (c) => '${c.flagEmoji} ${c.name}'.trim(),
              compareFn: (a, b) => a.id == b.id,
              dropdownBuilder: (context, selectedItem) => Text(
                selectedItem != null ? '${selectedItem.flagEmoji} ${selectedItem.name}'.trim() : 'Select country',
              ),
              popupProps: PopupProps.modalBottomSheet(
                showSearchBox: true,
                itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
                  title: Text('${item.flagEmoji} ${item.name}'.trim()),
                ),
              ),
              onChanged: (c) => setState(() {
                _selectedCountryId = c?.id;
                _selectedCityId = null;
              }),
              validator: (v) => v == null ? 'Required' : null,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            );
          },
          loading: () => const InputDecorator(
            decoration: InputDecoration(border: OutlineInputBorder()),
            child: SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: AppSpacing.md),
        // City
        Text('City', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor)),
        const SizedBox(height: 6),
        citiesAsync.when(
          data: (list) {
            _cities = list;
            if (list.isEmpty) return const SizedBox.shrink();
            final selected = list.where((c) => c.id == _selectedCityId).firstOrNull;
            return DropdownSearch<CityOption>(
              selectedItem: selected,
              items: (filter, loadProps) {
                if (list.isEmpty) return [];
                if (filter.isEmpty) return list;
                final f = filter.toLowerCase();
                return list.where((c) => c.name.toLowerCase().contains(f)).toList();
              },
              itemAsString: (c) => c.name,
              compareFn: (a, b) => a.id == b.id,
              dropdownBuilder: (context, selectedItem) => Text(selectedItem?.name ?? 'Select city'),
              popupProps: PopupProps.modalBottomSheet(
                showSearchBox: true,
                itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(title: Text(item.name)),
              ),
              onChanged: (c) => setState(() => _selectedCityId = c?.id),
              validator: (v) => v == null ? 'Required' : null,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            );
          },
          loading: () => const InputDecorator(
            decoration: InputDecoration(border: OutlineInputBorder()),
            child: SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        // Area / District
        Text('Area / District', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _areaDistrictController,
          decoration: const InputDecoration(
            hintText: 'e.g. Dubai Marina',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Commonly matched: Jumeirah Beach Residence, Marina Promenade',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
        ),
        const SizedBox(height: AppSpacing.md),
        // Street Address
        Text('Street Address', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _streetAddressController,
          decoration: InputDecoration(
            hintText: 'e.g. Al Marsa Street',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _streetNeedsReview ? AppConfig.warningOrange : AppConfig.borderColor,
                width: _streetNeedsReview ? 2 : 1,
              ),
            ),
          ),
          onChanged: (v) => setState(() => _streetNeedsReview = v.trim().isEmpty),
        ),
        if (_streetNeedsReview) ...[
          const SizedBox(height: 4),
          Text(
            'NEEDS REVIEW ▲',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppConfig.warningOrange),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        // Building / Villa / Suite
        Text(
          'Building / Villa / Suite',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _buildingController,
          decoration: InputDecoration(
            hintText: 'e.g. Silverene Tower B, Apt 1204',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step 2: Nickname & Confirmation',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppConfig.textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Address Nickname *',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: 'e.g. My Dubai Home',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Required for quick identification during checkout.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Address Type',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < AddressType.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _AddressTypeChip(
                  type: AddressType.values[i],
                  isSelected: _addressType == AddressType.values[i],
                  onTap: () => setState(() => _addressType = AddressType.values[i]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Pin Location Verification',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppConfig.textColor),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _markerPosition, zoom: 14),
              onMapCreated: (c) => _mapController = c,
              onTap: (LatLng pos) => setState(() {
                _lat = pos.latitude;
                _lng = pos.longitude;
              }),
              markers: {
                Marker(
                  markerId: const MarkerId('address'),
                  position: _markerPosition,
                  draggable: true,
                  onDragEnd: (LatLng pos) => setState(() {
                    _lat = pos.latitude;
                    _lng = pos.longitude;
                  }),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        if (_lat != null && _lng != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Lat: ${_lat!.toStringAsFixed(5)}, Long: ${_lng!.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20, color: AppConfig.primaryColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Logistics & Tax Optimization. We utilize these coordinates to calculate precise local delivery windows and pre-validate your region\'s VAT/Duty exemptions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile(
          title: const Text('Set as default address'),
          value: _isDefault,
          onChanged: (v) => setState(() => _isDefault = v),
          activeColor: AppConfig.primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.label, required this.isActive, required this.isDone});

  final int step;
  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppConfig.successGreen : (isActive ? AppConfig.primaryColor : AppConfig.borderColor),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isActive ? Colors.white : AppConfig.subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppConfig.primaryColor : AppConfig.subtitleColor,
              ),
        ),
      ],
    );
  }
}

class _AddressTypeChip extends StatelessWidget {
  const _AddressTypeChip({required this.type, required this.isSelected, required this.onTap});

  final AddressType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppConfig.primaryColor : AppConfig.borderColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              type.displayLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppConfig.textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplianceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.warningOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppConfig.warningOrange, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'International Compliance Notice',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppConfig.warningOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'To ensure seamless customs clearance and accurate tax calculation, please provide your legal address details. Discrepancies may lead to logistical holds or additional duties.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
