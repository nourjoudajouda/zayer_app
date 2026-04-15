import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Leading image for a PA request, or initials on brand-colored background.
class PurchaseAssistantStoreAvatar extends StatelessWidget {
  const PurchaseAssistantStoreAvatar({
    super.key,
    required this.imageUrl,
    required this.labelForInitials,
    this.size = 56,
    this.radius = AppConfig.radiusMedium,
  });

  final String? imageUrl;
  final String labelForInitials;
  final double size;
  final double radius;

  static String initialsFrom(String label) {
    final t = label.trim();
    if (t.isEmpty) return '?';
    String ch(String s) => s.isEmpty ? '' : s[0];
    final parts = t.split(RegExp(r'[\s./]+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${ch(parts[0])}${ch(parts[1])}'.toUpperCase();
    }
    if (t.length >= 2) {
      return t.substring(0, 2).toUpperCase();
    }
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = imageUrl?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(context),
          errorWidget: (_, __, ___) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final initials = initialsFrom(labelForInitials);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppConfig.borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppConfig.primaryColor,
            ),
      ),
    );
  }
}
