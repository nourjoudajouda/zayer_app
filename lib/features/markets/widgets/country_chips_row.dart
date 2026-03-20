import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/markets_providers.dart';
import '../../../core/config/models/app_bootstrap_config.dart';

/// Horizontal country filter chips.
class CountryChipsRow extends ConsumerWidget {
  const CountryChipsRow({super.key, required this.countries});

  final List<MarketCountryConfig> countries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCountryCodeProvider);

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: countries.length,
        itemBuilder: (context, i) {
          final c = countries[i];
          final isSelected = c.code == 'ALL'
              ? (selected == null || selected == 'ALL')
              : (selected != null && marketCountryCodesEqual(selected, c.code));

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _CountryChip(
              country: c,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedCountryCodeProvider.notifier).state =
                    c.code == 'ALL' ? null : c.code;
              },
            ),
          );
        },
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final MarketCountryConfig country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = country.flagEmoji.isEmpty ? country.name : '${country.flagEmoji} ${country.name}';

    return Material(
      color: isSelected ? Colors.white : AppConfig.borderColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppConfig.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppConfig.primaryColor : AppConfig.textColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
