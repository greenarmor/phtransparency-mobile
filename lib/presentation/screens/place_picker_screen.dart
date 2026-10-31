import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';
import '../widgets/place_scope_bar.dart';

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

  Future<void> _select(PlaceSelection place) async {
    await ref.read(placeProvider.notifier).select(place);
    if (!mounted) return;
    context.pop();
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
              hintText: 'Province, city, municipality or district',
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
          if (named.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ChoiceTile(
              icon: Icons.manage_search,
              title: 'Search the budget for "$named"',
              subtitle:
                  'Every line whose name says it: four 2027 programs and the enacted budgets',
              selected: current is NamedPlace && current.q == named,
              onTap: () => _select(NamedPlace(q: named, label: named)),
            ),
          ],
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
                      : 'Try the province name, or use "Search the budget for $named".',
                );
              }
              return Column(
                children: [
                  for (final district in page.districts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DistrictTile(
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
                        style: AppTheme.meta(size: 11.5),
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppTheme.accent : AppTheme.ruleSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.meta(size: 11.5)),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppTheme.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistrictTile extends StatelessWidget {
  const _DistrictTile({
    required this.district,
    required this.selected,
    required this.onTap,
  });

  final DistrictSummary district;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offices = district.offices.map((office) => office.name).join(', ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppTheme.accent : AppTheme.ruleSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      district.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.cardTitle(size: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppTheme.accent,
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [
                  district.jurisdiction,
                  district.region ?? '',
                  'Tier ${district.attributionCode}',
                ].where((part) => part.isNotEmpty).join(' · '),
                style: AppTheme.meta(size: 11.5),
              ),
              if (district.representativeName != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Rep. ${district.representativeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.meta(size: 11),
                ),
              ],
              if (offices.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  offices,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.meta(size: 11),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('House 2027', style: AppTheme.meta(size: 10.5)),
                  const SizedBox(width: 6),
                  Text(
                    compactPeso(district.house2027),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'NEP ${compactPeso(district.nep2027)}',
                    style: AppTheme.meta(size: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
