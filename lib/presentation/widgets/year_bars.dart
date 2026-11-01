import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';

class YearBars extends StatelessWidget {
  const YearBars({
    super.key,
    required this.amounts,
    required this.years,
    this.selected,
    this.height = 30,
    this.onDark = false,
  });

  final Map<int, int> amounts;
  final List<int> years;
  final int? selected;
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final max = amounts.values.fold<int>(0, (a, b) => b > a ? b : a);
    final barMax = (height - 19).clamp(3.0, height);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final year in years)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: max == 0
                          ? 2
                          : (2 + barMax * (amounts[year] ?? 0) / max).clamp(
                              2,
                              barMax,
                            ),
                      decoration: BoxDecoration(
                        color: year == selected
                            ? (onDark ? Colors.white : colors.accent)
                            : (onDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : colors.accent.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${year % 100}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: year == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: year == selected
                            ? (onDark ? Colors.white : colors.accent)
                            : (onDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : colors.inkMute),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class YearStrip extends StatelessWidget {
  const YearStrip({
    super.key,
    required this.totals,
    required this.selected,
    required this.onSelected,
  });

  final Map<int, int> totals;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final year in AppYears.values)
          ChoiceChip(
            label: Text('$year'),
            selected: year == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(year),
          ),
      ],
    );
  }
}

class AppYears {
  AppYears._();

  static const values = [2020, 2021, 2022, 2023, 2024, 2025, 2026];
}

String yearAmountLabel(Map<int, int> totals, int year) =>
    compactPeso(totals[year]);
