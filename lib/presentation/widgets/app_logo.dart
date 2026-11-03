import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88, this.asset, this.darkAsset});

  final double size;
  final String? asset;
  final String? darkAsset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosen = isDark ? (darkAsset ?? asset) : asset;

    if (chosen == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2A4A), Color(0xFFC8262C)],
          ),
        ),
        child: Center(
          child: Text(
            '₱',
            style: TextStyle(
              fontSize: size * 0.52,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: AppTheme.amountFeatures,
            ),
          ),
        ),
      );
    }

    final mark = SizedBox(
      width: size,
      height: size,
      child: Image.asset(chosen, fit: BoxFit.contain),
    );

    if (isDark && darkAsset == null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: mark,
      );
    }

    return mark;
  }
}
