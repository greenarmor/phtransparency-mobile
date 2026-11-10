import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/budget_providers.dart';
import '../../providers/gaa_browser_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/year_bars.dart';

class GaaBrowserScreen extends ConsumerWidget {
  const GaaBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAA budgets'),
            Text(
              'Enacted 2020–2026 · exact pesos',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: ref.watch(servingFromCacheProvider),
            builder: (context, fromCache, _) {
              if (!fromCache) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Saved data · the API is unreachable',
                onPressed: null,
                icon: Icon(
                  Icons.cloud_off_outlined,
                  color: context.colors.neutral,
                ),
              );
            },
          ),
        ],
      ),
      body: const GaaBrowserView(),
    );
  }
}

/// The browser body without its own Scaffold, so it can also live inside the
/// region shell as a tab page.
class GaaBrowserView extends ConsumerStatefulWidget {
  const GaaBrowserView({super.key});

  @override
  ConsumerState<GaaBrowserView> createState() => _GaaBrowserViewState();
}

class _GaaBrowserViewState extends ConsumerState<GaaBrowserView> {
  final _search = TextEditingController();
  int _year = AppConfig.gaaYears.last;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browser = ref.watch(gaaBrowserProvider);

    return AsyncView<GaaBrowserData>(
      value: browser,
      loadingLabel: 'Reading the enacted budgets…',
      onRetry: () => ref.invalidate(gaaBrowserProvider),
      builder: (context, data) => _body(context, data),
    );
  }

  Widget _body(BuildContext context, GaaBrowserData data) {
    final total = data.totalFor(_year);
    final departments = data.sortedFor(_year);
    final needle = _search.text.trim().toLowerCase();
    final visible = needle.isEmpty
        ? departments
        : departments
              .where(
                (department) =>
                    department.description.toLowerCase().contains(needle) ||
                    department.id == needle,
              )
              .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaBrowserProvider);
        await ref.read(gaaBrowserProvider.future);
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
                      HeroEyebrow('GENERAL APPROPRIATIONS ACT'),
                      const SizedBox(height: 8),
                      Text(
                        compactPeso(total),
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
                        'enacted for $_year · ${plural(
                          departments.length,
                          'department',
                        )}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: YearBars(
                          amounts: data.totals,
                          years: sortedYearKeys(data.totals),
                          selected: _year,
                          height: 58,
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                YearStrip(
                  totals: data.totals,
                  selected: _year,
                  onSelected: (year) => setState(() => _year = year),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search departments',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${plural(visible.length, 'department')} with money in $_year',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    Text(
                      yearAmountLabel(data.totals, _year),
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RegionalLink(year: _year),
              ],
            ),
          ),
          if (visible.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: 'No department matches',
                body: 'Try another name, or clear the search.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final department = visible[index];
                  return _DepartmentCard(
                    department: department,
                    year: _year,
                    nationalTotal: total,
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                const NoteCard(
                  title: 'The law, not a plan',
                  body:
                      'These are the enacted General Appropriations Act budgets, 2020 to 2026. '
                      'The 2027 NEP and House bill are proposals and are never added to them.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Source: General Appropriations Act via budget.bettergov.ph',
                  style: AppTheme.meta(context, size: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionalLink extends StatelessWidget {
  const _RegionalLink({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/gaa/regional?year=$year'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(Icons.map_outlined, size: 20, color: colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Where the money lands: GAA by region',
                  style: AppTheme.cardTitle(context, size: 14.5),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.inkMute),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.department,
    required this.year,
    required this.nationalTotal,
  });

  final GaaDepartment department;
  final int year;
  final int nationalTotal;

  @override
  Widget build(BuildContext context) {
    final amount = department.amountFor(year);
    final share = nationalTotal > 0 ? amount / nationalTotal : 0.0;
    final amounts = {
      for (final entry in department.years.entries) entry.key: entry.value.amount,
    };
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
                  AmountText(amount, size: 14),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      share > 0 ? '${_shareLabel(share)} of $year' : '',
                      style: AppTheme.meta(context, size: 11),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    plural(
                      department.years[year]?.count ?? 0,
                      'line',
                      'lines',
                    ),
                    style: AppTheme.meta(context, size: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              YearBars(
                amounts: amounts,
                years: sortedYearKeys(amounts),
                selected: year,
                height: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _shareLabel(double share) {
  if (share >= 0.001) return '${(share * 100).toStringAsFixed(1)}%';
  return '<0.1%';
}
