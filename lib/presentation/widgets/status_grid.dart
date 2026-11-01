import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import 'common.dart';

class StatusGrid extends StatelessWidget {
  const StatusGrid({
    super.key,
    required this.counts,
    this.selected,
    this.onSelected,
  });

  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final groups = groupOrder
        .where((group) => (counts[group] ?? 0) > 0)
        .toList();
    if (groups.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in groups)
              SizedBox(
                width: width,
                child: _StatusTile(
                  group: group,
                  rows: counts[group] ?? 0,
                  active: selected == group,
                  onTap: onSelected == null
                      ? null
                      : () => onSelected!(selected == group ? null : group),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.group,
    required this.rows,
    required this.active,
    this.onTap,
  });

  final String group;
  final int rows;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = StatusPill.colorFor(group, colors);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.08) : colors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.5) : colors.ruleSoft,
        ),
      ),
      child: Row(
        children: [
          Icon(StatusPill.iconFor(group), size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  groupShort[group] ?? group,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plural(rows, 'line'),
                  style: AppTheme.meta(context, size: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(
        container: true,
        label: '${groupShort[group] ?? group}, ${plural(rows, 'line')}',
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: active,
      label: '${groupShort[group] ?? group}, ${plural(rows, 'line')}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}
