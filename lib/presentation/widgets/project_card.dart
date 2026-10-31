import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/services/scope_service.dart';
import 'common.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.item, required this.onTap});

  final ScopedProject item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = item.project;
    final amount = row.housePhp ?? row.nepPhp;
    final hasBoth = row.nepPhp != null && row.housePhp != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cardTitle(),
              ),
              const SizedBox(height: 4),
              MetaLine(children: [row.office, row.program]),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(amount, size: 15),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      row.housePhp != null ? 'House' : 'NEP',
                      style: AppTheme.meta(size: 11.5),
                    ),
                  ),
                  const Spacer(),
                  StatusPill(
                    group: row.bridgeGroup,
                    label: groupShort[row.bridgeGroup] ?? row.statusLabel,
                    held: row.held,
                    compact: true,
                  ),
                ],
              ),
              if (hasBoth && row.deltaPhp != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'NEP ${compactPeso(row.nepPhp)}',
                      style: AppTheme.meta(size: 11.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      signedCompactPeso(row.deltaPhp),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: row.deltaPhp! >= 0
                            ? AppTheme.positive
                            : AppTheme.negative,
                        fontFeatures: AppTheme.amount.fontFeatures,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
