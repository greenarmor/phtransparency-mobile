import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../presentation/widgets/async_view.dart';
import '../../presentation/widgets/circle_menu_button.dart';
import '../../presentation/widgets/common.dart';
import '../../presentation/widgets/hero_card.dart';
import '../../presentation/widgets/place_sheet.dart';
import '../../presentation/widgets/section_label.dart';
import '../../presentation/widgets/status_grid.dart';
import '../../presentation/widgets/version_figure.dart';
import '../../providers/budget_providers.dart';

class NationalScreen extends ConsumerWidget {
  const NationalScreen({super.key});

  void _openRegion(BuildContext context, WidgetRef ref, RegionRow region) {
    if (region.nepPhp == null && region.housePhp == null) return;
    ref
        .read(placeProvider.notifier)
        .select(
          RegionPlace(key: region.key, label: region.label, name: region.name),
        );
    context.go('/region/${region.key}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);
    final regions = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Philippines'),
            Text(
              'FY ${AppConfig.fiscalYear} · NEP vs House bill',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About this app',
            onPressed: () {
              logTabOpen('about');
              context.push('/about');
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(overviewProvider);
              ref.invalidate(regionsProvider);
              await ref.read(overviewProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
              children: [
                AsyncView<Overview>(
                  value: overview,
                  loadingLabel: 'Reading the national totals…',
                  onRetry: () => ref.invalidate(overviewProvider),
                  builder: (context, data) {
                    final totals = NationalTotals.of(data.datasets);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NationalHero(totals: totals),
                        const SizedBox(height: 12),
                        _NationalGroups(totals: totals),
                        const SectionLabel('The four programs'),
                        for (final dataset in data.datasets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DatasetRow(dataset: dataset),
                          ),
                        const SizedBox(height: 4),
                        for (final disclaimer in data.disclaimers.take(1))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: NoteCard(
                              title: disclaimer.title,
                              body: disclaimer.body,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SectionLabel('Regions · DPWH infrastructure'),
                AsyncView<RegionsPage>(
                  value: regions,
                  loadingLabel: 'Reading the 18 regions…',
                  onRetry: () => ref.invalidate(regionsProvider),
                  builder: (context, page) => Column(
                    children: [
                      for (final region in page.regions)
                        if (region.nepPhp != null || region.housePhp != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RegionRow(
                              region: region,
                              onTap: () => _openRegion(context, ref, region),
                            ),
                          ),
                      if (page.notOnMapHouse != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: NoteCard(
                            title: 'Nationwide, on no region',
                            body:
                                '${compactPeso(page.notOnMapNep)} NEP and ${compactPeso(page.notOnMapHouse)} House bill are listed as nationwide rather than in one region.',
                            icon: Icons.public,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          page.note,
                          style: AppTheme.meta(context, size: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: CircleMenuButton(onOpen: () => showPlaceSheet(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class NationalTotals {
  NationalTotals({
    required this.nepPhp,
    required this.housePhp,
    required this.nepRows,
    required this.houseRows,
    required this.unconfirmed,
    required this.groups,
    required this.datasets,
  });

  final int nepPhp;
  final int housePhp;
  final int nepRows;
  final int houseRows;
  final int unconfirmed;
  final Map<String, ({int rows, int php, int unconfirmed})> groups;
  final List<DatasetTotals> datasets;

  factory NationalTotals.of(List<DatasetTotals> datasets) {
    var nep = 0;
    var house = 0;
    var nepRows = 0;
    var houseRows = 0;
    var unconfirmed = 0;
    final groups = <String, ({int rows, int php, int unconfirmed})>{};
    for (final dataset in datasets) {
      nep += dataset.nepPhp ?? 0;
      house += dataset.housePhp ?? 0;
      nepRows += dataset.nepRows ?? 0;
      houseRows += dataset.houseRows ?? 0;
      for (final entry in dataset.groups.entries) {
        final cell = groups.putIfAbsent(
          entry.key,
          () => (rows: 0, php: 0, unconfirmed: 0),
        );
        groups[entry.key] = (
          rows: cell.rows + entry.value.rows,
          php: cell.php + entry.value.php,
          unconfirmed: cell.unconfirmed + entry.value.unconfirmedRows,
        );
        unconfirmed += entry.value.unconfirmedRows;
      }
    }
    return NationalTotals(
      nepPhp: nep,
      housePhp: house,
      nepRows: nepRows,
      houseRows: houseRows,
      unconfirmed: unconfirmed,
      groups: groups,
      datasets: datasets,
    );
  }
}

class _NationalHero extends StatelessWidget {
  const _NationalHero({required this.totals});

  final NationalTotals totals;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroEyebrow('FY ${AppConfig.fiscalYear} · THE WHOLE COUNTRY'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VersionFigure(
                  label: 'NEP',
                  amount: totals.nepPhp,
                  rows: totals.nepRows,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: VersionFigure(
                  label: 'House bill',
                  amount: totals.housePhp,
                  rows: totals.houseRows,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Four programs. Two versions of one budget: compared, never added.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${totals.datasets.length} programs · ${totals.groups.length} status groups',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              if (totals.unconfirmed > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${totals.unconfirmed} to check',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NationalGroups extends StatelessWidget {
  const _NationalGroups({required this.totals});

  final NationalTotals totals;

  @override
  Widget build(BuildContext context) {
    return StatusGrid(
      counts: {
        for (final entry in totals.groups.entries) entry.key: entry.value.rows,
      },
    );
  }
}

class _DatasetRow extends StatelessWidget {
  const _DatasetRow({required this.dataset});

  final DatasetTotals dataset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.ruleSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dataset.short,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                compactPeso(dataset.nepPhp),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                compactPeso(dataset.housePhp),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({required this.region, required this.onTap});

  final RegionRow region;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.name.isEmpty
                          ? region.label
                          : '${region.label} · ${region.name}',
                      style: AppTheme.cardTitle(context, size: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plural(region.nepRows ?? 0, 'NEP line')} · '
                      '${plural(region.houseRows ?? 0, 'House line')}',
                      style: AppTheme.meta(context, size: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    compactPeso(region.housePhp),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    signedCompactPeso(region.deltaPhp),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (region.deltaPhp ?? 0) >= 0
                          ? colors.positive
                          : colors.negative,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 18, color: colors.inkMute),
            ],
          ),
        ),
      ),
    );
  }
}
