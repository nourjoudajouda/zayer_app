import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'providers/settings_providers.dart';

/// Screen to select default warehouse. Data from GET /api/warehouses.
class DefaultWarehouseScreen extends ConsumerWidget {
  const DefaultWarehouseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(effectiveSettingsProvider);
    final warehousesAsync = ref.watch(warehousesProvider);
    final currentId = settings.defaultWarehouseId;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Default Warehouse'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: warehousesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (warehouses) {
            if (warehouses.isEmpty) {
              return Center(
                child: Text(
                  'No warehouses available',
                  style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: warehouses.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final w = warehouses[i];
                final id = w.id;
                final label = w.label;
                final isSelected = currentId == id;
                return Material(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                  child: InkWell(
                    onTap: () {
                      ref.read(settingsOverridesProvider.notifier).setWarehouse(id, label);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Default warehouse: $label')),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? AppConfig.primaryColor
                              : AppConfig.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warehouse_outlined,
                            color: isSelected
                                ? AppConfig.primaryColor
                                : AppConfig.subtitleColor,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              label,
                              style: AppTextStyles.titleMedium(
                                isSelected ? AppConfig.primaryColor : AppConfig.textColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppConfig.primaryColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
          },
        );
        },
      )
    ),
  );
  }
}
