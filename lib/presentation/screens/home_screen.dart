import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../data/services/scope_service.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/place_scope_bar.dart';
import '../widgets/project_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String? _group;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(placeProvider);
    final scope = ref.watch(scopeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(place.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              'FY ${AppConfig.fiscalYear} · NEP vs House bill',
              style: AppTheme.meta(size: 11.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Choose a place',
            onPressed: () => context.push('/place'),
            icon: const Icon(Icons.place_outlined),
          ),
        ],
      ),
      body: place is NationalPlace
          ? const _NationalBody()
          : AsyncView<ScopeResult>(
              value: scope,
              loadingLabel: 'Reading ${place.title}…',
              onRetry: () => ref.invalidate(scopeProvider),
              builder: (context, result) => _placeBody(place, result),
            ),
    );
  }

  Widget _placeBody(PlaceSelection place, ScopeResult result) {
    final needle = _search.text.trim().toLowerCase();
    final filtered = result.projects.where((item) {
      final row = item.project;
      if (_group != null && row.bridgeGroup != _group) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${row.title} ${row.office ?? ''} ${row.program ?? ''} ${row.pap ?? ''}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(scopeProvider);
        await ref.read(scopeProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                PlaceScopeBar(
                  place: place,
                  onTap: () => context.push('/place'),
                ),
                const SizedBox(height: 12),
                _SummaryCard(summary: result.summary, scopeName: place.title),
                const SizedBox(height: 14),
                _GroupGrid(
                  summary: result.summary,
                  selected: _group,
                  onSelected: (group) =>
                      setState(() => _group = group == _group ? null : group),
                ),
                if (result.note != null) ...[
                  const SizedBox(height: 12),
                  NoteCard(
                    title: 'Reading this scope',
                    body: result.note!,
                    tint: AppTheme.neutral,
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search projects, offices, programs',
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
                const SizedBox(height: 10),
                _FilterRow(
                  summary: result.summary,
                  selected: _group,
                  onSelected: (group) => setState(() => _group = group),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${filtered.length} of ${result.projects.length} projects',
                        style: AppTheme.meta(size: 12.5),
                      ),
                    ),
                    Text('By House amount', style: AppTheme.meta(size: 11.5)),
                  ],
                ),
                if (result.truncated) ...[
                  const SizedBox(height: 10),
                  const NoteCard(
                    title: 'This scope is wider than one place',
                    body:
                        'The API returned more rows than one view should hold, so the list is cut at 4,000.',
                    icon: Icons.warning_amber_outlined,
                    tint: AppTheme.neutral,
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (filtered.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                title: 'No lines match',
                body: 'Try a shorter search, or clear the status filter.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return ProjectCard(
                    item: item,
                    onTap: () {
                      unawaited(
                        logProjectOpen(
                          dataset: item.project.dataset,
                          id: item.project.id,
                        ),
                      );
                      context.push(
                        '/project/${item.project.dataset}/${Uri.encodeComponent(item.project.id)}',
                      );
                    },
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            sliver: SliverList.list(
              children: [
                for (final disclaimer in result.disclaimers.take(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NoteCard(
                      title: disclaimer.title,
                      body: disclaimer.body,
                    ),
                  ),
                Text(
                  'Data from the BetterGov.ph Budget API · '
                  '${result.meta == null ? '' : shortDate(result.meta!.builtAt)}',
                  style: AppTheme.meta(size: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NationalBody extends ConsumerWidget {
  const _NationalBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeProvider);
    final overview = ref.watch(overviewProvider);
    final regions = ref.watch(regionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(overviewProvider);
        ref.invalidate(regionsProvider);
        await ref.read(overviewProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          PlaceScopeBar(place: place, onTap: () => context.push('/place')),
          const SizedBox(height: 12),
          AsyncView<Overview>(
            value: overview,
            loadingLabel: 'Reading the national totals…',
            onRetry: () => ref.invalidate(overviewProvider),
            builder: (context, data) {
              final totals = _NationalTotals.of(data.datasets);
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
            builder: (context, data) => Column(
              children: [
                for (final region in data.regions)
                  if (region.nepPhp != null || region.housePhp != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RegionRow(
                        region: region,
                        onTap: () {
                          ref
                              .read(placeProvider.notifier)
                              .select(
                                RegionPlace(
                                  key: region.key,
                                  label: region.label,
                                  name: region.name,
                                ),
                              );
                          ref.invalidate(scopeProvider);
                        },
                      ),
                    ),
                if (data.notOnMapHouse != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: NoteCard(
                      title: 'Nationwide, on no region',
                      body:
                          '${compactPeso(data.notOnMapNep)} NEP and ${compactPeso(data.notOnMapHouse)} House bill are listed as nationwide rather than in one region.',
                      icon: Icons.public,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data.note, style: AppTheme.meta(size: 11.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a district or a place',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All 254 legislative districts, every region, or any city, '
                    'municipality or province by name. The app remembers your choice.',
                    style: AppTheme.meta(size: 12.5),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/place'),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Choose a place'),
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

class _NationalTotals {
  _NationalTotals({
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
  final Map<String, GroupCell> groups;
  final List<DatasetTotals> datasets;

  factory _NationalTotals.of(List<DatasetTotals> datasets) {
    var nep = 0;
    var house = 0;
    var nepRows = 0;
    var houseRows = 0;
    var unconfirmed = 0;
    final groups = <String, GroupCell>{};
    for (final dataset in datasets) {
      nep += dataset.nepPhp ?? 0;
      house += dataset.housePhp ?? 0;
      nepRows += dataset.nepRows ?? 0;
      houseRows += dataset.houseRows ?? 0;
      for (final entry in dataset.groups.entries) {
        final cell = groups.putIfAbsent(entry.key, GroupCell.new);
        cell.rows += entry.value.rows;
        cell.php += entry.value.php;
        unconfirmed += entry.value.unconfirmedRows;
      }
    }
    return _NationalTotals(
      nepPhp: nep,
      housePhp: house,
      nepRows: nepRows,
      houseRows: houseRows,
      unconfirmed: unconfirmed,
      groups: groups,
      datasets: datasets,
    );
  }

  Summary asSummary() => Summary(
    rows: nepRows + houseRows,
    nepRows: nepRows,
    nepPhp: nepPhp,
    houseRows: houseRows,
    housePhp: housePhp,
    unconfirmed: unconfirmed,
    groups: groups,
  );
}

class _NationalHero extends StatelessWidget {
  const _NationalHero({required this.totals});

  final _NationalTotals totals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FY ${AppConfig.fiscalYear} · THE WHOLE COUNTRY',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _VersionFigure(
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
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _VersionFigure(
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
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 7),
              Text(
                '${totals.datasets.length} programs · ${totals.groups.length} status groups',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              if (totals.unconfirmed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${totals.unconfirmed} to check',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VersionFigure extends StatelessWidget {
  const _VersionFigure({
    required this.label,
    required this.amount,
    required this.rows,
    this.alignEnd = false,
  });

  final String label;
  final int amount;
  final int rows;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          compactPeso(amount),
          style: const TextStyle(
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plural(rows, 'line'),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _NationalGroups extends StatelessWidget {
  const _NationalGroups({required this.totals});

  final _NationalTotals totals;

  @override
  Widget build(BuildContext context) {
    final groups = groupOrder
        .where((group) => (totals.groups[group]?.rows ?? 0) > 0)
        .toList();
    if (groups.isEmpty) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        for (final group in groups)
          _GroupTile(
            group: group,
            rows: totals.groups[group]!.rows,
            active: false,
            onTap: null,
          ),
      ],
    );
  }
}

class _DatasetRow extends StatelessWidget {
  const _DatasetRow({required this.dataset});

  final DatasetTotals dataset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ruleSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dataset.short,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                compactPeso(dataset.nepPhp),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                compactPeso(dataset.housePhp),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
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
                      style: AppTheme.cardTitle(size: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plural(region.nepRows ?? 0, 'NEP line')} · '
                      '${plural(region.houseRows ?? 0, 'House line')}',
                      style: AppTheme.meta(size: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    compactPeso(region.housePhp),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    signedCompactPeso(region.deltaPhp),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (region.deltaPhp ?? 0) >= 0
                          ? AppTheme.positive
                          : AppTheme.negative,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.inkMute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.scopeName});

  final Summary summary;
  final String scopeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FY ${AppConfig.fiscalYear} · ${scopeName.toUpperCase()}',
            maxLines: 2,
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _VersionFigure(
                  label: 'NEP',
                  amount: summary.nepPhp,
                  rows: summary.nepRows,
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
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 1,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _VersionFigure(
                  label: 'House bill',
                  amount: summary.housePhp,
                  rows: summary.houseRows,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Two versions of one budget. Compared, never added.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 7),
              Text(
                plural(summary.rows, 'project line'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              if (summary.unconfirmed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.unconfirmed} to check',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({
    required this.summary,
    required this.selected,
    required this.onSelected,
  });

  final Summary summary;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final groups = groupOrder
        .where((group) => (summary.groups[group]?.rows ?? 0) > 0)
        .toList();
    if (groups.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        for (final group in groups)
          _GroupTile(
            group: group,
            rows: summary.groups[group]!.rows,
            active: selected == group,
            onTap: () => onSelected(group),
          ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.rows,
    required this.active,
    required this.onTap,
  });

  final String group;
  final int rows;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = StatusPill.colorFor(group);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.08) : AppTheme.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : AppTheme.ruleSoft,
          ),
        ),
        child: Row(
          children: [
            Icon(StatusPill.iconFor(group), size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    groupShort[group] ?? group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(plural(rows, 'line'), style: AppTheme.meta(size: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.summary,
    required this.selected,
    required this.onSelected,
  });

  final Summary summary;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('All statuses'),
            selected: selected == null,
            showCheckmark: false,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 6),
          for (final group in groupOrder)
            if ((summary.groups[group]?.rows ?? 0) > 0) ...[
              ChoiceChip(
                label: Text(groupShort[group] ?? group),
                selected: selected == group,
                showCheckmark: false,
                onSelected: (_) => onSelected(group),
              ),
              const SizedBox(width: 6),
            ],
        ],
      ),
    );
  }
}
