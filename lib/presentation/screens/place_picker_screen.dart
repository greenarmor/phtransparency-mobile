import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/district_tile.dart';
import '../widgets/section_label.dart';

class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key});

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
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

  void _select(PlaceSelection place) {
    ref.read(placeProvider.notifier).select(place);
    if (!mounted) return;
    switch (place) {
      case NationalPlace():
        context.go('/');
      case RegionPlace():
        context.go('/region/${place.key}');
      case DistrictPlace():
      case NamedPlace():
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(placeProvider);
    final districts = ref.watch(districtsProvider(_q));
    final regions = ref.watch(regionsProvider);
    final named = _q.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a place')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            controller: _search,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Province or district',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _search.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _ChoiceTile(
            icon: Icons.public,
            title: 'All Philippines',
            subtitle: 'Every region, district and office',
            selected: current is NationalPlace,
            onTap: () => _select(const NationalPlace()),
          ),
          const SectionLabel('Regions'),
          AsyncView<RegionsPage>(
            value: regions,
            loadingLabel: 'Reading the 18 regions…',
            onRetry: () => ref.invalidate(regionsProvider),
            builder: (context, page) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final region in page.regions)
                  if (region.nepPhp != null || region.housePhp != null)
                    ChoiceChip(
                      label: Text(
                        region.name.isEmpty
                            ? region.label
                            : '${region.label} · ${region.name}',
                      ),
                      selected:
                          current is RegionPlace && current.key == region.key,
                      showCheckmark: false,
                      onSelected: (_) => _select(
                        RegionPlace(
                          key: region.key,
                          label: region.label,
                          name: region.name,
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SectionLabel('Legislative districts'),
          AsyncView<DistrictPage>(
            value: districts,
            loadingLabel: 'Reading the 254 districts…',
            onRetry: () => ref.invalidate(districtsProvider(_q)),
            builder: (context, page) {
              if (page.districts.isEmpty) {
                return EmptyState(
                  title: 'No district matches',
                  body: named.isEmpty
                      ? 'The district list could not be read.'
                      : 'No district, province or office is named "$named". '
                            'Try the province name, or pick the region above.',
                );
              }
              return Column(
                children: [
                  for (final district in page.districts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DistrictTile(
                        district: district,
                        selected:
                            current is DistrictPlace &&
                            current.id == district.id,
                        onTap: () => _select(
                          DistrictPlace(
                            id: district.id,
                            label: district.label,
                            jurisdiction: district.jurisdiction,
                            regionKey: district.regionKey,
                          ),
                        ),
                      ),
                    ),
                  if (page.total > page.districts.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Showing ${page.districts.length} of ${page.total} districts. '
                        'Type a province, city or district to narrow the list.',
                        style: AppTheme.meta(context, size: 11.5),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const NoteCard(
            title: 'Names are matched, not places surveyed',
            body:
                'The API places DPWH money by office and other lines by the place '
                'their title names. A project whose name does not say where it is '
                'will not appear under a name search. City and municipality '
                'boundaries are not yet in the API.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.meta(context, size: 11.5)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
