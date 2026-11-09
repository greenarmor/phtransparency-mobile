import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/place.dart';
import '../../data/services/gaa_service.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/year_bars.dart';

class EnactedScreen extends ConsumerStatefulWidget {
  const EnactedScreen({super.key});

  @override
  ConsumerState<EnactedScreen> createState() => _EnactedScreenState();
}

class _EnactedScreenState extends ConsumerState<EnactedScreen> {
  final _search = TextEditingController();
  int _year = AppConfig.gaaYears.last;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gaa = ref.watch(gaaProvider);
    final place = ref.watch(placeProvider);

    return AsyncView<GaaDataset>(
      value: gaa,
      loadingLabel: place is NationalPlace || place is RegionPlace
          ? 'Reading the national enacted budgets…'
          : 'Searching 38 departments for ${place.title}…',
      onRetry: () => ref.invalidate(gaaProvider),
      builder: (context, data) => _body(context, place, data),
    );
  }

  Widget _body(BuildContext context, PlaceSelection place, GaaDataset data) {
    final colors = context.colors;
    final rows = data.fundedIn(_year, query: _search.text);
    final total = data.totalFor(_year);
    // The hero states the year's whole total, so its count must not follow
    // the search box the way the list below does.
    final funded = _search.text.trim().isEmpty
        ? rows.length
        : data.fundedIn(_year).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaProvider);
        await ref.read(gaaProvider.future);
      },
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  'Enacted budgets',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '2020–2026 · appropriations',
                  style: AppTheme.meta(context, size: 12.5),
                ),
                const SizedBox(height: 12),
                if (data.regionFallback) ...[
                  NoteCard(
                    title: 'The GAA has no region filter',
                    body:
                        'The enacted budgets are not published by region, so the national totals are shown. Pick a district or a place to narrow them by name.',
                    tint: colors.neutral,
                  ),
                  const SizedBox(height: 12),
                ],
                _YearHeader(
                  year: _year,
                  total: total,
                  rows: funded,
                  national: data.national,
                  years: AppConfig.gaaYears,
                  totals: data.totals,
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
                    hintText: 'Search programs and departments',
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
                        data.national
                            ? '${plural(rows.length, 'department')} with money in $_year'
                            : '${plural(rows.length, 'program')} funded in $_year',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    Text(
                      data.national ? 'National totals' : 'Named "${data.q}"',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (rows.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: 'Nothing funded in this year',
                body:
                    'A year counts only where the amount is above zero. Try another year or clear the search.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _GaaCard(row: row, year: _year);
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            sliver: SliverList.list(
              children: [
                const NoteCard(
                  title: 'Authority to spend, not spending',
                  body:
                      'Enacted amounts are appropriations. Years are shown side by side; the 2027 NEP and House bill are not added to them.',
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 10),
                Text(
                  data.national
                      ? '${plural(data.rows.length, 'department')} · national totals, all years.'
                      : '${plural(data.rows.length, 'program family', 'program families')} across '
                            '${plural(data.departmentsSearched, 'department')} · matched by name.',
                  style: AppTheme.meta(context, size: 11.5),
                ),
                if (data.truncated) ...[
                  const SizedBox(height: 6),
                  Text(
                    'The list was cut at 6,000 families for one department. '
                    'Make the place name more specific.',
                    style: AppTheme.meta(context, size: 11.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({
    required this.year,
    required this.total,
    required this.rows,
    required this.national,
    required this.years,
    required this.totals,
  });

  final int year;
  final int total;
  final int rows;
  final bool national;
  final List<int> years;
  final Map<int, int> totals;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroEyebrow('ENACTED IN $year'),
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
            national
                ? plural(rows, 'department funded', 'departments funded')
                : plural(rows, 'program funded', 'programs funded'),
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
              amounts: totals,
              years: years,
              selected: year,
              height: 58,
              onDark: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaaCard extends StatelessWidget {
  const _GaaCard({required this.row, required this.year});

  final GaaRow row;
  final int year;

  @override
  Widget build(BuildContext context) {
    final program = row.program;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle(context, size: 14.5),
            ),
            if (row.department.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                row.department,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.meta(context, size: 11.5),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                AmountText(program.amountFor(year), size: 14),
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
                  plural(program.idsCount, 'line'),
                  style: AppTheme.meta(context, size: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            YearBars(
              amounts: {
                for (final entry in program.years.entries)
                  entry.key: entry.value.amount,
              },
              years: AppConfig.gaaYears,
              selected: year,
              height: 34,
            ),
          ],
        ),
      ),
    );
  }
}
