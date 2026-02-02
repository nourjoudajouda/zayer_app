import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Your cart is empty',
            style: TextStyle(color: AppConfig.subtitleColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
