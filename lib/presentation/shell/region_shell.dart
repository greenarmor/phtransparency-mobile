import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/firebase/analytics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../providers/budget_providers.dart';
import '../place_nav.dart';
import '../screens/enacted_screen.dart';
import '../screens/region_screen.dart';
import '../widgets/region_tab_bar.dart';

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class RegionShell extends ConsumerStatefulWidget {
  const RegionShell({
    super.key,
    required this.regionKey,
    required this.location,
    required this.child,
  });

  final String regionKey;
  final String location;
  final Widget child;

  @override
  ConsumerState<RegionShell> createState() => _RegionShellState();
}

class _RegionShellState extends ConsumerState<RegionShell> {
  bool _labelFixed = false;
  late final PageController _pager = PageController(initialPage: _index);

  int get _index => widget.location.endsWith('/enacted') ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _syncPlace();
  }

  @override
  void didUpdateWidget(RegionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.regionKey != widget.regionKey) {
      _labelFixed = false;
      _syncPlace();
    }
    if (oldWidget.location != widget.location) _syncPager();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _syncPager() {
    if (!_pager.hasClients) return;
    if ((_pager.page?.round() ?? _index) == _index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pager.jumpToPage(_index);
      return;
    }
    _pager.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncPlace() {
    if (widget.regionKey == regionAllKey) return;
    final place = ref.read(placeProvider);
    if (place is DistrictPlace || place is NamedPlace) return;
    if (place is RegionPlace && place.key == widget.regionKey) return;
    ref
        .read(placeProvider.notifier)
        .select(RegionPlace(key: widget.regionKey, label: widget.regionKey));
  }

  RegionRow? _row(RegionsPage? page, String key) {
    if (page == null) return null;
    for (final region in page.regions) {
      if (region.key == key) return region;
    }
    return null;
  }

  void _fixLabel(RegionRow row) {
    if (_labelFixed) return;
    final place = ref.read(placeProvider);
    if (place is RegionPlace &&
        place.key == widget.regionKey &&
        place.label == widget.regionKey) {
      _labelFixed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(placeProvider.notifier)
            .select(
              RegionPlace(key: row.key, label: row.label, name: row.name),
            );
      });
    }
  }

  void _back() {
    ref.read(placeProvider.notifier).select(const NationalPlace());
    context.go('/');
  }

  /// The region view is reached with `go`, so it is the only page on the
  /// stack and a system back would close the app. Back walks the same way the
  /// app bar does instead: Enacted returns to Money, Money to the Philippines.
  void _onSystemBack(bool didPop, Object? _) {
    if (didPop) return;
    if (_index == 1) {
      _go(0);
    } else {
      _back();
    }
  }

  void _go(int target) {
    final current = _index;
    if (target == current) return;
    if (target == 0) {
      logTabOpen('money');
      context.go('/region/${widget.regionKey}');
    } else {
      logTabOpen('enacted');
      context.go('/region/${widget.regionKey}/enacted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(placeProvider);
    final regionsPage = ref.watch(regionsProvider).asData?.value;
    final row = _row(regionsPage, widget.regionKey);
    if (row != null) _fixLabel(row);

    final String title;
    final String subtitle;
    if (place is DistrictPlace) {
      title = place.title;
      subtitle = place.subtitle;
    } else if (place is NamedPlace) {
      title = place.title;
      subtitle = place.subtitle;
    } else {
      title = row?.label ?? place.title;
      subtitle = row == null || row.name.isEmpty
          ? 'Region'
          : 'Region · ${row.name}';
    }

    final index = _index;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onSystemBack,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to the Philippines',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            IconButton(
              tooltip: 'Change place',
              onPressed: () => context.push('/place'),
              icon: const Icon(Icons.place_outlined),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // go_router's shell navigator. Its pages are empty (the tabs are
            // the PageView below), but it must stay mounted: a system back
            // walks it, and an unmounted one throws and closes the app.
            Offstage(child: widget.child),
            PageView(
              controller: _pager,
              onPageChanged: _go,
              children: const [
                _KeepAlive(child: RegionMoneyScreen()),
                _KeepAlive(child: EnactedScreen()),
              ],
            ),
          ],
        ),
        bottomNavigationBar: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: FractionalTranslation(
              translation: Offset(0, 0.35 * (1 - value)),
              child: child,
            ),
          ),
          child: RegionTabBar(index: index, onSelected: _go),
        ),
      ),
    );
  }
}
