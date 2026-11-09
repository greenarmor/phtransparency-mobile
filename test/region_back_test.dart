import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/data/models/place.dart';
import 'package:bettergov_budget/data/services/gaa_service.dart';
import 'package:bettergov_budget/data/services/scope_service.dart';
import 'package:bettergov_budget/providers/budget_providers.dart';
import 'package:bettergov_budget/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _regions = RegionsPage(
  regions: [
    RegionRow(
      key: 'VII',
      label: 'Region VII',
      name: 'Central Visayas',
      nepPhp: 17720000000,
      housePhp: 20370000000,
      deltaPhp: 2650000000,
      nepRows: 492,
      houseRows: 696,
    ),
  ],
  notOnMapNep: null,
  notOnMapHouse: null,
  note: '',
);

final _scope = ScopeResult(
  projects: const [],
  disclaimers: const [],
  summary: Summary.of(const []),
  meta: null,
  truncated: false,
  national: false,
  note: null,
);

const _gaa = GaaDataset(
  rows: [],
  totals: {},
  q: '',
  departmentsSearched: 0,
  matchedFamilies: 0,
  truncated: false,
  national: true,
  scopeLabel: 'All Philippines',
  regionFallback: true,
);

/// Runs the real app router, so the region ShellRoute is the one the app
/// ships, with the network providers stubbed out.
Future<GoRouter> _open(WidgetTester tester, String location) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      overviewProvider.overrideWith(
        (ref) async => const Overview(
          title: '',
          summary: '',
          rules: [],
          disclaimers: [],
          meta: BudgetMeta(dataset: 'hgab', notice: ''),
          datasets: [],
        ),
      ),
      regionsProvider.overrideWith((ref) async => _regions),
      scopeProvider.overrideWith((ref) async => _scope),
      gaaProvider.overrideWith((ref) async => _gaa),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  // The app picks the place before it navigates (national list, place sheet,
  // place picker); the shell only confirms it.
  container
      .read(placeProvider.notifier)
      .select(
        const RegionPlace(
          key: 'VII',
          label: 'Region VII',
          name: 'Central Visayas',
        ),
      );
  router.go(location);
  await tester.pumpAndSettle();
  return router;
}

/// Records whether the framework asked Android to close the app.
List<String> _watchPlatform(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('system back on a region returns to the Philippines', (
    tester,
  ) async {
    final router = await _open(tester, '/region/VII');
    final platform = _watchPlatform(tester);
    expect(find.text('Money'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_path(router), '/');
    expect(platform, isNot(contains('SystemNavigator.pop')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back on the Enacted tab returns to Money first', (
    tester,
  ) async {
    final router = await _open(tester, '/region/VII/enacted');
    final platform = _watchPlatform(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_path(router), '/region/VII');
    expect(platform, isNot(contains('SystemNavigator.pop')));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_path(router), '/');
    expect(platform, isNot(contains('SystemNavigator.pop')));
    expect(tester.takeException(), isNull);
  });
}
