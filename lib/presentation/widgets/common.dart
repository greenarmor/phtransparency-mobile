import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/services/scope_service.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.group,
    required this.label,
    this.held = false,
    this.compact = false,
  });

  final String group;
  final String label;
  final bool held;
  final bool compact;

  static Color colorFor(String group, AppColors colors) {
    switch (group) {
      case 'house_only':
        return colors.accent;
      case 'nep_only':
        return colors.ink3;
      case 'increased':
        return colors.positive;
      case 'decreased':
        return colors.neutral;
      case 'scope_review':
        return const Color(0xFF6B5B95);
      default:
        return colors.inkMute;
    }
  }

  static IconData iconFor(String group) {
    switch (group) {
      case 'house_only':
        return Icons.add_circle_outline;
      case 'nep_only':
        return Icons.remove_circle_outline;
      case 'increased':
        return Icons.trending_up;
      case 'decreased':
        return Icons.trending_down;
      case 'scope_review':
        return Icons.compare_arrows;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = colorFor(group, colors);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(group), size: compact ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (held) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.help_outline,
              size: compact ? 11 : 13,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}

class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.size = 15,
    this.compact = true,
    this.color,
  });

  final int? amount;
  final double size;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      compact ? compactPeso(amount) : fullPeso(amount),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? colors.ink,
        fontFeatures: AppTheme.amountFeatures,
        letterSpacing: -0.2,
      ),
    );
  }
}

class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.children});

  final List<String?> children;

  @override
  Widget build(BuildContext context) {
    final parts = children
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.meta(context),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: colors.ink3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

String projectReasonLabel(Reason reason) =>
    reason.kind == 'office' ? reason.label : 'Named "${reason.label}"';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
    this.tint,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = tint ?? colors.ink3;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.ruleSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(body, style: AppTheme.meta(context, size: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 36, color: colors.inkMute),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.cardTitle(context, size: 15)),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTheme.meta(context),
          ),
        ],
      ),
    );
  }
}

String groupLabelOf(ProjectRow row) => row.groupLabel.isEmpty
    ? (groupShort[row.bridgeGroup] ?? row.statusLabel)
    : row.groupLabel;
