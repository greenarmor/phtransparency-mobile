import 'package:flutter/material.dart';

import '../../core/utils/format.dart';

class VersionFigure extends StatelessWidget {
  const VersionFigure({
    super.key,
    required this.label,
    required this.amount,
    required this.rows,
    this.alignEnd = false,
  });

  final String label;
  final int amount;
  final int rows;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          compactPeso(amount),
          style: const TextStyle(
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plural(rows, 'line'),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}
