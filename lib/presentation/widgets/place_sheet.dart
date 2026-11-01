import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../providers/budget_providers.dart';
import '../../data/services/scope_service.dart';
import '../place_nav.dart';
import 'async_view.dart';
import 'district_tile.dart';
import 'section_label.dart';

Future<void> showPlaceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 200),
      reverseDuration: Duration(milliseconds: 160),
    ),
    builder: (context) => const PlaceSheet(),
  );
}

const _regionGroups = <(String, List<String>)>[
  ('Metro Manila', ['NCR']),
  ('Luzon', ['CAR', 'I', 'II', 'III', 'IV-A', 'MIMAROPA', 'V']),
  ('Visayas', ['VI', 'NIR', 'VII', 'VIII']),
  ('Mindanao', ['IX', 'X', 'XI', 'XII', 'XIII', 'BARMM']),
];

class PlaceSheet extends ConsumerStatefulWidget {
  const PlaceSheet({super.key});

  @override
  ConsumerState<PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<PlaceSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _q = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _q = value.trim());
    });
  }

  void _choose(PlaceSelection place) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    ref.read(placeProvider.notifier).select(place);
    router.go(placePath(place));
  }

  bool _matchesRegion(RegionRow region, String needle) => [
    region.key,
    region.label,
    region.name,
  ].join(' ').toLowerCase().contains(needle);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final place = ref.watch(placeProvider);
    final needle = _q.toLowerCase();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where in the Philippines?',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FY ${AppConfig.fiscalYear} · NEP vs House bill',
                    style: AppTheme.meta(context, size: 12.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _search,
                builder: (context, value, _) => TextField(
                  controller: _search,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Region',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _search.clear();
                              _onChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ),
            Expanded(child: _regions(place, needle)),
          ],
        ),
      ),
    );
  }

  Widget _regions(PlaceSelection place, String needle) {
    final regions = ref.watch(regionsProvider);
    return AsyncView<RegionsPage>(
      value: regions,
      loadingLabel: 'Reading the 18 regions…',
      onRetry: () => ref.invalidate(regionsProvider),
      builder: (context, page) {
        final byKey = {for (final region in page.regions) region.key: region};
        final groups = <(String, List<RegionRow>)>[];
        for (final group in _regionGroups) {
          final matches = [
            for (final key in group.$2)
              if (byKey[key] != null && _matchesRegion(byKey[key]!, needle))
                byKey[key]!,
          ];
          if (matches.isNotEmpty) groups.add((group.$1, matches));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (needle.isEmpty)
              _AllPhilippinesTile(
                selected: place is NationalPlace,
                onTap: () => _choose(const NationalPlace()),
              ),
            if (needle.isNotEmpty && groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No region matches "$_q".',
                  textAlign: TextAlign.center,
                  style: AppTheme.meta(context, size: 12.5),
                ),
              ),
            for (final group in groups) ...[
              SectionLabel(group.$1),
              for (final region in group.$2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RegionTile(
                    region: region,
                    onTap: region.nepPhp == null && region.housePhp == null
                        ? null
                        : () => _choose(
                            RegionPlace(
                              key: region.key,
                              label: region.label,
                              name: region.name,
                            ),
                          ),
                  ),
                ),
            ],
            if (needle.isNotEmpty) ...[
              const SectionLabel('Legislative districts'),
              AsyncView<DistrictSearch>(
                value: ref.watch(districtSearchProvider(_q)),
                loadingLabel: 'Looking for districts…',
                onRetry: () => ref.invalidate(districtSearchProvider(_q)),
                builder: (context, search) {
                  if (search.districts.isEmpty) {
                    return Text(
                      'No district is named "$_q", and no published office '
                      'builds a line naming it. Every district is reachable '
                      'inside its region.',
                      style: AppTheme.meta(context, size: 12.5),
                    );
                  }
                  final caption = switch (search.match) {
                    DistrictMatch.office =>
                      'No district is named "$_q". These are the districts '
                          'whose offices build the lines naming it.',
                    DistrictMatch.province =>
                      'The API does not say which district contains "$_q". '
                          'These are the districts of ${search.province}: '
                          'the candidate is among them.',
                    _ => null,
                  };
                  return Column(
                    children: [
                      for (final district in search.districts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DistrictTile(
                            district: district,
                            selected:
                                place is DistrictPlace &&
                                place.id == district.id,
                            onTap: () => _choose(
                              DistrictPlace(
                                id: district.id,
                                label: district.label,
                                jurisdiction: district.jurisdiction,
                                regionKey: district.regionKey,
                              ),
                            ),
                          ),
                        ),
                      if (caption != null)
                        Text(
                          caption,
                          style: AppTheme.meta(context, size: 11.5),
                        ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              needle.isEmpty
                  ? 'Region totals follow the DPWH region each document '
                        'lists. Districts are available inside a region.'
                  : 'Search finds the 18 regions. Districts and their offices '
                        'are available inside a region.',
              style: AppTheme.meta(context, size: 11.5),
            ),
          ],
        );
      },
    );
  }
}

class _AllPhilippinesTile extends StatelessWidget {
  const _AllPhilippinesTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? colors.accent : colors.ruleSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Icon(Icons.public, size: 22, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Philippines',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'The whole national budget, every region',
                      style: AppTheme.meta(context, size: 11.5),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: colors.accent)
              else
                Icon(Icons.chevron_right, size: 20, color: colors.inkMute),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({required this.region, required this.onTap});

  final RegionRow region;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                        style: AppTheme.cardTitle(context, size: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? '${plural(region.nepRows ?? 0, 'NEP line')} · '
                                  '${plural(region.houseRows ?? 0, 'House line')}'
                            : 'No DPWH data published for this region',
                        style: AppTheme.meta(context, size: 11),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right, size: 20, color: colors.inkMute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
