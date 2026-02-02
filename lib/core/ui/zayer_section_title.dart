import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_text_styles.dart';

/// Zayer section title for headings.
class ZayerSectionTitle extends StatelessWidget {
  const ZayerSectionTitle({
    super.key,
    required this.title,
    this.color,
  });

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleLarge(color ?? AppConfig.textColor),
    );
  }
}
