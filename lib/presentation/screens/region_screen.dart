import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/place.dart';
import '../../data/services/scope_service.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/hero_card.dart';
import '../widgets/project_card.dart';
import '../widgets/scope_map.dart';
import '../widgets/status_grid.dart';
import '../widgets/version_figure.dart';

class RegionMoneyScreen extends ConsumerStatefulWidget {
  const RegionMoneyScreen({super.key});

  @override
  ConsumerState<RegionMoneyScreen> createState() => _RegionMoneyScreenState();
}

class _RegionMoneyScreenState extends ConsumerState<RegionMoneyScreen> {
  final _search = TextEditingController();
  String? _group;
  bool _map = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(scopeProvider);
    final place = ref.watch(placeProvider);

    return AsyncView<ScopeResult>(
      value: scope,
      loadingLabel: 'Reading ${place.title}…',
      onRetry: () => ref.invalidate(scopeProvider),
      builder: (context, result) => _body(context, place, result),
    );
  }

  Widget _body(BuildContext context, PlaceSelection place, ScopeResult result) {
    final colors = context.colors;
    if (result.projects.isEmpty && !result.national) {
      return _noLines(context, place, result);
    }

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
    final anyPoints = mappableProjects(result.projects).isNotEmpty;
    final points = _map
        ? mappableProjects(result.projects, group: _group, query: _search.text)
        : const <ScopedProject>[];

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
                _SummaryCard(summary: result.summary, scopeName: place.title),
                const SizedBox(height: 14),
                StatusGrid(
                  counts: {
                    for (final entry in result.summary.groups.entries)
                      entry.key: entry.value.rows,
                  },
                  selected: _group,
                  onSelected: (group) => setState(() => _group = group),
                ),
                if (result.note != null) ...[
                  const SizedBox(height: 12),
                  NoteCard(
                    title: 'Reading this scope',
                    body: result.note!,
                    tint: colors.neutral,
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
                if (anyPoints) ...[
                  const SizedBox(height: 10),
                  _ViewToggle(
                    map: _map,
                    onChanged: (value) => setState(() => _map = value),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _map
                            ? '${points.length} of ${result.projects.length} lines with coordinates'
                            : '${filtered.length} of ${result.projects.length} projects',
                        style: AppTheme.meta(context, size: 12.5),
                      ),
                    ),
                    Text(
                      _map
                          ? 'Dot size · House amount'
                          : 'Sorted by House amount',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
                if (result.truncated) ...[
                  const SizedBox(height: 10),
                  NoteCard(
                    title: 'This scope is wider than one view',
                    body:
                        'The API returned more rows than one view should hold, so the list is cut at 4,000.',
                    icon: Icons.warning_amber_outlined,
                    tint: colors.neutral,
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
          if (_map)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.list(
                children: [
                  ScopeMap(points: points, height: 320),
                  const SizedBox(height: 10),
                  NoteCard(
                    title: 'What the map shows',
                    body:
                        'Only lines whose documents publish coordinates. '
                        'DPWH roads and all farm-to-market roads do; health '
                        'facilities and irrigation do not.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: points.isEmpty
                          ? null
                          : () => context.push('/map'),
                      icon: const Icon(Icons.open_in_full, size: 18),
                      label: const Text('Open the full map'),
                    ),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
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
                      logProjectOpen(
                        dataset: item.project.dataset,
                        id: item.project.id,
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
                  style: AppTheme.meta(context, size: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noLines(
    BuildContext context,
    PlaceSelection place,
    ScopeResult result,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        EmptyState(
          title: 'No 2027 line names "${place.title}"',
          body:
              'The API matches projects by the place their title names, so a '
              'line that never spells the place out will not appear here. Try '
              'the district list, or a shorter name.',
        ),
        if (result.disclaimers.isNotEmpty)
          NoteCard(
            title: result.disclaimers.first.title,
            body: result.disclaimers.first.body,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.scopeName});

  final Summary summary;
  final String scopeName;

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroEyebrow(
            'FY ${AppConfig.fiscalYear} · ${scopeName.toUpperCase()}',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VersionFigure(
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
                Icons.receipt_long_outlined,
                size: 15,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  plural(summary.rows, 'project line'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              if (summary.unconfirmed > 0) ...[
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
                    '${summary.unconfirmed} to check',
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

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.map, required this.onChanged});

  final bool map;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.view_list_outlined, size: 16),
            label: Text('List'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.map_outlined, size: 16),
            label: Text('Map'),
          ),
        ],
        selected: {map},
        showSelectedIcon: false,
        onSelectionChanged: (value) => onChanged(value.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
