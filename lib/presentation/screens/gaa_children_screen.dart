import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/gaa_browser_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class GaaChildrenScreen extends ConsumerWidget {
  const GaaChildrenScreen({
    super.key,
    required this.year,
    required this.departmentId,
    required this.level,
    this.parent,
    this.label,
  });

  final int year;
  final String departmentId;
  final String level;
  final String? parent;
  final String? label;

  static const _order = <String>[
    'agencies',
    'fpaps',
    'operating_units',
    'fund_subcategories',
    'expenses',
  ];

  static const _names = <String, String>{
    'agencies': 'Agencies and bureaus',
    'fpaps': 'Programs (P/A/P)',
    'operating_units': 'Operating units',
    'fund_subcategories': 'Funds',
    'expenses': 'Expense classes',
  };

  static String levelName(String level) => _names[level] ?? level;

  static bool canDrillDeeper(String level) {
    final index = _order.indexOf(level);
    return index >= 0 && index < _order.length - 1;
  }

  static String? nextLevel(String level) {
    final index = _order.indexOf(level);
    if (index < 0 || index >= _order.length - 1) return null;
    return _order[index + 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = GaaChildrenArgs(
      year: year,
      departmentId: departmentId,
      level: _order.contains(level) ? level : 'agencies',
      parent: parent,
    );
    final page = ref.watch(gaaChildrenProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (label == null || label!.isEmpty)
                  ? levelName(args.level)
                  : label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
            Text(
              '${levelName(args.level)} · FY $year',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
      ),
      body: AsyncView<GaaChildrenPage>(
        value: page,
        loadingLabel: 'Reading the ${levelName(args.level).toLowerCase()}…',
        onRetry: () => ref.invalidate(gaaChildrenProvider(args)),
        builder: (context, data) => _body(context, ref, args, data),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    GaaChildrenArgs args,
    GaaChildrenPage data,
  ) {
    final next = nextLevel(args.level);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaChildrenProvider(args));
        await ref.read(gaaChildrenProvider(args).future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${plural(data.rows.length, 'entry')} · largest first',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    if (data.matchedAmount > 0)
                      Text(
                        compactPeso(data.matchedAmount),
                        style: AppTheme.meta(context, size: 11.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (data.rows.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: 'Nothing at this level',
                body: 'This branch of the GAA has no rows for the year.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: data.rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = data.rows[index];
                  return _ChildCard(
                    row: row,
                    year: year,
                    departmentId: args.departmentId,
                    nextLevel: next,
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                if (next != null)
                  NoteCard(
                    title: 'Keep drilling',
                    body:
                        'Tap an entry to open its ${levelName(next).toLowerCase()}. '
                        'The last level is expense classes — Personnel Services, '
                        'MOOE, Financial Expenses and Capital Outlays.',
                  )
                else
                  const NoteCard(
                    title: 'The finest level',
                    body:
                        'Expense classes split the fund into Personnel Services, '
                        'MOOE, Financial Expenses and Capital Outlays.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.row,
    required this.year,
    required this.departmentId,
    required this.nextLevel,
  });

  final GaaChildRow row;
  final int year;
  final String departmentId;
  final String? nextLevel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle(context, size: 14.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AmountText(row.amount, size: 14),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  'in $year',
                  style: AppTheme.meta(context, size: 11),
                ),
              ),
              const Spacer(),
              Text(
                plural(row.lineItems, 'line', 'lines'),
                style: AppTheme.meta(context, size: 11),
              ),
            ],
          ),
        ],
      ),
    );

    if (nextLevel == null) {
      return Card(child: body);
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          '/gaa/$year/departments/$departmentId/children'
          '?level=$nextLevel&parent=${Uri.encodeComponent(row.id)}'
          '&label=${Uri.encodeComponent(row.description)}',
        ),
        child: Row(
          children: [
            Expanded(child: body),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, size: 20, color: colors.inkMute),
            ),
          ],
        ),
      ),
    );
  }
}
