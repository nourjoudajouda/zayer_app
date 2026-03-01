import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Small pill for order item badges (e.g. Customs, Lithium).
class OrderBadgePill extends StatelessWidget {
  const OrderBadgePill({super.key, required this.label, this.isWarning = false});

  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppConfig.warningOrange : AppConfig.subtitleColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isWarning ? Icons.battery_charging_full : Icons.shield_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
