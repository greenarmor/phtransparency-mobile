import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/gaa_browser_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/year_bars.dart';

class GaaYearScreen extends ConsumerWidget {
  const GaaYearScreen({super.key, required this.year});

  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(gaaSnapshotProvider(year));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FY $year GAA'),
            Text(
              'Every department and its share',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
      ),
      body: AsyncView<GaaSnapshot>(
        value: snapshot,
        loadingLabel: 'Reading the FY $year enacted budget…',
        onRetry: () => ref.invalidate(gaaSnapshotProvider(year)),
        builder: (context, data) => _body(context, ref, data),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, GaaSnapshot data) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaSnapshotProvider(year));
        await ref.read(gaaSnapshotProvider(year).future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeroEyebrow('ENACTED IN ${data.year}'),
                      const SizedBox(height: 8),
                      Text(
                        compactPeso(data.totalAmount),
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plural(data.totalLineItems, 'line item')} across '
                        '${plural(data.departments.length, 'department')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                YearStrip(
                  totals: {year: data.totalAmount},
                  selected: year,
                  onSelected: (next) => context.go('/gaa/$next'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${plural(data.departments.length, 'department')} · largest share first',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    Text(
                      'shares of the FY $year total',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: data.departments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final department = data.departments[index];
                return _ShareCard(department: department, year: year);
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                const NoteCard(
                  title: 'How to read the share',
                  body:
                      'Each share is the department\'s slice of the national '
                      'enacted budget for the year. Tap a department for its '
                      'agencies, expense classes and seven-year history.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.department, required this.year});

  final GaaSnapshotDepartment department;
  final int year;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final share = department.share;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/gaa/$year/departments/${department.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                department.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cardTitle(context, size: 14.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AmountText(department.amount, size: 14),
                  const Spacer(),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}%',
                    style: AppTheme.meta(context, size: 11.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: colors.accent.withValues(alpha: 0.15)),
                      FractionallySizedBox(
                        widthFactor: share.clamp(0.0, 1.0),
                        child: Container(color: colors.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plural(department.lineItems, 'line item'),
                style: AppTheme.meta(context, size: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
