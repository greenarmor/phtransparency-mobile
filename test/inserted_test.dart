import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/presentation/screens/inserted_screen.dart';
import 'package:bettergov_budget/presentation/screens/national_screen.dart';
import 'package:bettergov_budget/providers/budget_providers.dart';
import 'package:bettergov_budget/providers/campaign_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

ProjectRow _row({
  required String id,
  required String title,
  String dataset = 'dpwh',
  String? office,
  String? region,
  int house = 1000000,
}) {
  return ProjectRow(
    id: id,
    dataset: dataset,
    title: title,
    program: dataset.toUpperCase(),
    pap: null,
    office: office,
    region: region,
    regionKey: null,
    statusLabel: 'In the House bill only',
    bridgeGroup: 'house_only',
    groupLabel: 'In the House bill only',
    held: false,
    nepPhp: null,
    hgab2Php: null,
    hgab3Php: null,
    housePhp: house,
    apiPhp: null,
    deltaPhp: null,
    nepPage: null,
    hgab2Page: null,
    hgab3Page: null,
    pdfUrl: const {},
    flags: const [],
    url: '',
  );
}

final _carmen = _row(
  id: 'carmen-road',
  dataset: 'fmr',
  title: 'Farm-to-market road in Carmen, Bohol',
  office: 'Bohol 2nd DEO',
  region: 'Region VII',
  house: 50000000,
);

final _cebu = _row(
  id: 'cebu-flood',
  title: 'Flood control in Cebu City',
  office: 'Cebu City DEO',
  region: 'Region VII',
  house: 20000000,
);

Overview _overview() => const Overview(
  title: 'FY2027 House bill against the NEP',
  summary: 'Every project line set against the NEP.',
  rules: [],
  disclaimers: [],
  meta: BudgetMeta(dataset: 'hgab', notice: 'Published notice.'),
  datasets: [],
);

Widget _app({required String location}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const NationalScreen()),
      GoRoute(
        path: '/inserted',
        builder: (context, state) => const InsertedScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const Scaffold(body: Text('about page')),
      ),
      GoRoute(
        path: '/project/:dataset/:id',
        builder: (context, state) => Scaffold(
          body: Text(
            'project ${state.pathParameters['dataset']}/${state.pathParameters['id']}',
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      insertedProjectsProvider.overrideWith((ref) async => [_carmen, _cebu]),
      overviewProvider.overrideWith((ref) async => _overview()),
      regionsProvider.overrideWith(
        (ref) async => const RegionsPage(
          regions: [],
          notOnMapNep: null,
          notOnMapHouse: null,
          note: '',
        ),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

Future<void> _open(WidgetTester tester, {String location = '/inserted'}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(location: location));
  await tester.pumpAndSettle();
}

void main() {
  test('search matches title, office, region and dataset', () {
    expect(filterInsertedProjects([_carmen, _cebu], ''), [_carmen, _cebu]);
    expect(filterInsertedProjects([_carmen, _cebu], 'carmen'), [_carmen]);
    expect(filterInsertedProjects([_carmen, _cebu], 'CEBU CITY'), [_cebu]);
    expect(filterInsertedProjects([_carmen, _cebu], 'fmr'), [_carmen]);
    expect(filterInsertedProjects([_carmen, _cebu], 'region vii'), [
      _carmen,
      _cebu,
    ]);
    expect(filterInsertedProjects([_carmen, _cebu], 'no such line'), isEmpty);
  });

  test('the prebuilt index finds exactly what the plain filter finds', () {
    final rows = List<ProjectRow>.unmodifiable([_carmen, _cebu]);
    final index = InsertedIndex(rows);

    expect(identical(index.filter('  '), rows), isTrue);
    for (final query in [
      'carmen',
      'CEBU CITY',
      'fmr',
      'region vii',
      ' bohol ',
      'no such line',
    ]) {
      expect(
        index.filter(query),
        filterInsertedProjects(rows, query),
        reason: query,
      );
    }
  });

  testWidgets('the inserted page lists every House-only line', (tester) async {
    await _open(tester);

    expect(find.text('Inserted projects'), findsOneWidget);
    expect(find.text('FY 2027 · House bill only'), findsOneWidget);
    expect(find.text('2 inserted projects'), findsOneWidget);
    expect(find.text('Farm-to-market road in Carmen, Bohol'), findsOneWidget);
    expect(find.text('Flood control in Cebu City'), findsOneWidget);
    expect(find.text('Search titles, offices, regions'), findsOneWidget);
    expect(find.byTooltip('Download the CSV list'), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });

  testWidgets('the search box keeps only matching inserted lines', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'carmen');
    await tester.pump();

    expect(find.text('1 of 2 inserted projects'), findsOneWidget);
    expect(find.text('Farm-to-market road in Carmen, Bohol'), findsOneWidget);
    expect(find.text('Flood control in Cebu City'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(find.text('2 inserted projects'), findsOneWidget);
    expect(find.text('Flood control in Cebu City'), findsOneWidget);
  });

  testWidgets('a search with no match says so', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'manila');
    await tester.pump();

    expect(find.text('No inserted projects match'), findsOneWidget);
    expect(find.text('Farm-to-market road in Carmen, Bohol'), findsNothing);
  });

  testWidgets('tapping a line opens the project page', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Farm-to-market road in Carmen, Bohol'));
    await tester.pumpAndSettle();

    expect(find.text('project fmr/carmen-road'), findsOneWidget);
  });

  testWidgets('the budget app bar opens inserted projects before About', (
    tester,
  ) async {
    await _open(tester, location: '/');

    final inserted = tester.getTopLeft(find.byTooltip('Inserted projects'));
    final about = tester.getTopLeft(find.byTooltip('About this app'));
    expect(inserted.dx, lessThan(about.dx));
    expect(find.byIcon(Icons.post_add), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.post_add))
          .color,
      AppColors.light.accent,
    );

    await tester.tap(find.byTooltip('Inserted projects'));
    await tester.pumpAndSettle();

    expect(find.text('Inserted projects'), findsOneWidget);
    expect(find.text('Farm-to-market road in Carmen, Bohol'), findsOneWidget);
  });
}
