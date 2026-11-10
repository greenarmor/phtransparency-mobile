import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/gaa_browser_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/year_bars.dart';

class GaaRegionalScreen extends ConsumerStatefulWidget {
  const GaaRegionalScreen({super.key, this.initialYear});

  final int? initialYear;

  @override
  ConsumerState<GaaRegionalScreen> createState() => _GaaRegionalScreenState();
}

class _GaaRegionalScreenState extends ConsumerState<GaaRegionalScreen> {
  late int _year = widget.initialYear ?? 2022;

  @override
  Widget build(BuildContext context) {
    final regional = ref.watch(gaaRegionalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAA by region'),
            Text(
              'Where the budget lands',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        ),
      ),
      body: AsyncView<GaaRegional>(
        value: regional,
        loadingLabel: 'Reading the regional allocations…',
        onRetry: () => ref.invalidate(gaaRegionalProvider),
        builder: (context, data) => _body(context, data),
      ),
    );
  }

  Widget _body(BuildContext context, GaaRegional data) {
    final years = data.years.map((entry) => entry.year).toList();
    if (years.contains(_year) == false && years.isNotEmpty) {
      _year = years.last;
    }
    final entry = data.forYear(_year);
    final regions = entry?.regions ?? const <GaaRegionAllocation>[];
    final known = regions.where((region) => !region.isUnknown).toList();
    final unknown = regions.where((region) => region.isUnknown).toList();
    final unknownAmount = unknown.fold<int>(0, (sum, row) => sum + row.amount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gaaRegionalProvider);
        await ref.read(gaaRegionalProvider.future);
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
                      HeroEyebrow('GAA ALLOCATED TO REGIONS · $_year'),
                      const SizedBox(height: 8),
                      Text(
                        compactPeso(entry?.total ?? 0),
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
                        '${plural(known.length, 'region')} with a named allocation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (years.isNotEmpty)
                  YearStrip(
                    totals: {
                      for (final item in data.years) item.year: item.total,
                    },
                    selected: _year,
                    onSelected: (year) => setState(() => _year = year),
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: known.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _RegionCard(
                region: known[index],
                year: _year,
                total: entry?.total ?? 0,
              ),
            ),
          ),
          if (unknownAmount > 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
                  NoteCard(
                    title: '${compactPeso(unknownAmount)} on no named region',
                    body:
                        'The source publishes ${unknown.map((row) => row.region).join(', ')} '
                        'buckets: central offices and lines the documents do not '
                        'place in one region.',
                    icon: Icons.public_outlined,
                  ),
                ],
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                const NoteCard(
                  title: 'A second source, read with care',
                  body:
                      'These regional figures come from the BetterGov '
                      'transparency dashboard, derived from DBM publications. '
                      'FY2020 is only partly broken out by region and FY2026 is '
                      'not published here yet — the per-year totals still match '
                      'the enacted GAA from 2021 on.',
                ),
                const SizedBox(height: 10),
                Text(
                  'Source: ${data.source} · transparency.bettergov.ph',
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

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.year,
    required this.total,
  });

  final GaaRegionAllocation region;
  final int year;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final share = total > 0 ? region.amount / total : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              region.region,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.cardTitle(context, size: 14.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AmountText(region.amount, size: 14),
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
          ],
        ),
      ),
    );
  }
}
