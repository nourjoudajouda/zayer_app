import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Reusable badge pill (e.g. ACTION REQUIRED, Verified, DEFAULT).
class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppConfig.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
