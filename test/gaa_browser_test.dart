import 'package:bettergov_budget/core/config/app_config.dart';
import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/presentation/screens/gaa_browser_screen.dart';
import 'package:bettergov_budget/presentation/screens/gaa_children_screen.dart';
import 'package:bettergov_budget/presentation/screens/gaa_department_screen.dart';
import 'package:bettergov_budget/presentation/screens/gaa_regional_screen.dart';
import 'package:bettergov_budget/presentation/screens/gaa_year_screen.dart';
import 'package:bettergov_budget/presentation/screens/national_screen.dart';
import 'package:bettergov_budget/presentation/widgets/year_bars.dart';
import 'package:bettergov_budget/providers/budget_providers.dart';
import 'package:bettergov_budget/providers/gaa_browser_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GaaDepartment _department(
  String id,
  String description, {
  int count2026 = 10,
  int amount2026 = 1000,
  int amount2025 = 900,
}) {
  return GaaDepartment(
    id: id,
    description: description,
    years: {
      2025: GaaYearAmount(count: count2026, amount: amount2025),
      2026: GaaYearAmount(count: count2026, amount: amount2026),
    },
  );
}

final _national = GaaBrowserData(
  totals: {2025: 900, 2026: 1000},
  departments: [
    _department('18', 'Department of Public Works and Highways (DPWH)'),
    _department('07', 'Department of Education (DepEd)', amount2026: 500),
  ],
);

final _snapshot2026 = GaaSnapshot(
  year: 2026,
  totalAmount: 1000,
  totalLineItems: 42,
  departments: const [
    GaaSnapshotDepartment(
      id: '18',
      slug: 'dpwh',
      description: 'Department of Public Works and Highways (DPWH)',
      lineItems: 20,
      amount: 700,
      share: 0.7,
    ),
    GaaSnapshotDepartment(
      id: '07',
      slug: 'deped',
      description: 'Department of Education (DepEd)',
      lineItems: 22,
      amount: 300,
      share: 0.3,
    ),
  ],
);

final _dpwhDetail = GaaDepartmentDetail(
  department: _department('18', 'Department of Public Works and Highways (DPWH)'),
  agencies: [
    GaaAgency(
      id: '18-001',
      slug: 'office-of-the-secretary',
      description: 'Office of the Secretary',
      departmentId: '18',
      years: {2026: GaaYearAmount(count: 20, amount: 700)},
    ),
  ],
  expenseClasses: [
    GaaExpenseClass(
      code: '1',
      label: 'Personnel Services',
      years: {2026: GaaYearAmount(count: 4, amount: 50)},
    ),
    GaaExpenseClass(
      code: '6',
      label: 'Capital Outlays',
      years: {2026: GaaYearAmount(count: 9, amount: 600)},
    ),
  ],
);

GaaChildrenPage _children(String level, {String? parent}) {
  return GaaChildrenPage(
    level: level,
    rows: [
      GaaChildRow(
        id: parent == null ? '18-001' : 'fpap-1',
        slug: 'row-1',
        description: parent == null ? 'Office of the Secretary' : 'Roads',
        departmentId: '18',
        year: 2026,
        lineItems: 9,
        amount: 600,
      ),
    ],
    matched: 1,
    matchedAmount: 600,
  );
}

final _regional = GaaRegional(
  years: [
    GaaRegionYear(
      year: 2022,
      regions: const [
        GaaRegionAllocation(region: 'National Capital Region (NCR)', amount: 900),
        GaaRegionAllocation(region: 'Region Unknown', amount: 100),
      ],
      total: 1000,
    ),
  ],
  source: 'Department of Budget and Management (DBM)',
);

Widget _app({required String location}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const NationalScreen()),
      GoRoute(
        path: '/gaa',
        builder: (context, state) => const GaaBrowserScreen(),
        routes: [
          GoRoute(
            path: 'regional',
            builder: (context, state) => GaaRegionalScreen(
              initialYear: int.tryParse(
                state.uri.queryParameters['year'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: ':year',
            builder: (context, state) => GaaYearScreen(
              year: int.parse(state.pathParameters['year'] ?? '2026'),
            ),
            routes: [
              GoRoute(
                path: 'departments/:id',
                builder: (context, state) => GaaDepartmentScreen(
                  year: int.parse(state.pathParameters['year'] ?? '2026'),
                  departmentId: state.pathParameters['id'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'children',
                    builder: (context, state) => GaaChildrenScreen(
                      year: int.parse(state.pathParameters['year'] ?? '2026'),
                      departmentId: state.pathParameters['id'] ?? '',
                      level: state.uri.queryParameters['level'] ?? 'agencies',
                      parent: state.uri.queryParameters['parent'],
                      label: state.uri.queryParameters['label'],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      overviewProvider.overrideWith((ref) async => const Overview(
            title: '',
            summary: '',
            rules: [],
            disclaimers: [],
            meta: BudgetMeta(dataset: 'hgab', notice: ''),
            datasets: [],
          )),
      regionsProvider.overrideWith(
        (ref) async => const RegionsPage(
          regions: [],
          notOnMapNep: null,
          notOnMapHouse: null,
          note: '',
        ),
      ),
      gaaBrowserProvider.overrideWith((ref) async => _national),
      gaaSnapshotProvider(2026).overrideWith(
        (ref) async => _snapshot2026,
      ),
      gaaDepartmentProvider('18').overrideWith(
        (ref) async => _dpwhDetail,
      ),
      gaaChildrenProvider(
        const GaaChildrenArgs(
          year: 2026,
          departmentId: '18',
          level: 'agencies',
        ),
      ).overrideWith((ref) async => _children('agencies')),
      gaaChildrenProvider(
        const GaaChildrenArgs(
          year: 2026,
          departmentId: '18',
          level: 'fpaps',
          parent: '18-001',
        ),
      ).overrideWith((ref) async => _children('fpaps', parent: '18-001')),
      gaaRegionalProvider.overrideWith((ref) async => _regional),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

Future<void> _open(WidgetTester tester, {String location = '/gaa'}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(location: location));
  await tester.pumpAndSettle();
}

void main() {
  test('the snapshot envelope parses and ranks departments by amount', () {
    final snapshot = GaaSnapshot.fromEnvelope({
      'meta': {'year': 2022},
      'data': {
        'total': {'year': 2022, 'line_items': 10, 'amount': 1500},
        'departments': [
          {
            'id': '07',
            'slug': 'deped',
            'description': 'Department of Education (DepEd)',
            'year': 2022,
            'line_items': 4,
            'amount': 500,
            'share': 0.3333,
          },
          {
            'id': '18',
            'slug': 'dpwh',
            'description': 'DPWH',
            'year': 2022,
            'line_items': 6,
            'amount': 1000,
            'share': 0.6667,
          },
        ],
      },
    }, 2022);

    expect(snapshot.year, 2022);
    expect(snapshot.totalAmount, 1500);
    expect(snapshot.totalLineItems, 10);
    expect(snapshot.departments.map((row) => row.id), ['18', '07']);
    expect(snapshot.departments.first.share, 0.6667);
  });

  test('the department envelope parses agencies and expense classes', () {
    final detail = GaaDepartmentDetail.fromEnvelope({
      'data': {
        'department': {
          'id': '18',
          'description': 'DPWH',
          'years': {'2026': {'count': 9, 'amount': 700}},
        },
        'agencies': [
          {
            'id': '18-001',
            'slug': 'ots',
            'description': 'Office of the Secretary',
            'department_id': '18',
            'years': {'2026': {'count': 9, 'amount': 700}},
          },
        ],
        'expense_classes': [
          {
            'expense_code': '6',
            'label': 'Capital Outlays',
            'years': {'2026': {'count': 9, 'amount': 600}},
          },
          {
            'expense_code': '2',
            'years': {'2026': {'count': 4, 'amount': 50}},
          },
        ],
      },
    });

    expect(detail.department.id, '18');
    expect(detail.department.amountFor(2026), 700);
    expect(detail.agencies.single.description, 'Office of the Secretary');
    expect(detail.expenseClasses.first.label, 'Capital Outlays');
    expect(
      detail.expenseClasses.last.label,
      'Maintenance and Other Operating Expenses',
    );
    expect(detail.expenseClasses.last.amountFor(2026), 50);
  });

  test('the children envelope parses level, rows and matched totals', () {
    final page = GaaChildrenPage.fromEnvelope({
      'meta': {
        'level': 'fpaps',
        'matched': 12,
        'matched_amount': 4500,
      },
      'data': [
        {
          'id': 'fpap-1',
          'slug': 'roads',
          'description': 'Roads and bridges',
          'department_id': '18',
          'year': 2026,
          'line_items': 9,
          'amount': 600,
        },
      ],
    });

    expect(page.level, 'fpaps');
    expect(page.matched, 12);
    expect(page.matchedAmount, 4500);
    expect(page.rows.single.description, 'Roads and bridges');
    expect(page.rows.single.amount, 600);
  });

  test('the regional envelope sorts years and flags unknown buckets', () {
    final regional = GaaRegional.fromEnvelope({
      'metadata': {'source': 'Department of Budget and Management (DBM)'},
      'data': [
        {
          'year': 2022,
          'regions': [
            {'region': 'Region Unknown', 'gaa': 100.0},
            {'region': 'National Capital Region (NCR)', 'gaa': 900.0},
          ],
          'total': 1000.0,
        },
        {
          'year': 2021,
          'regions': [
            {'region': 'National Capital Region (NCR)', 'gaa': 800.0},
          ],
          'total': 800.0,
        },
      ],
    });

    expect(regional.source, 'Department of Budget and Management (DBM)');
    expect(regional.years.map((year) => year.year), [2021, 2022]);
    expect(regional.forYear(2022)!.regions.first.region, contains('NCR'));
    expect(regional.forYear(2022)!.regions.last.isUnknown, isTrue);
    expect(regional.forYear(2026), isNull);
  });

  test('normalizeGaaYear keeps valid years and falls back to 2026', () {
    expect(normalizeGaaYear('2022'), 2022);
    expect(normalizeGaaYear('1999'), AppConfig.gaaYears.last);
    expect(normalizeGaaYear('regional'), AppConfig.gaaYears.last);
  });

  test('the hierarchy knows its drill order', () {
    expect(GaaChildrenScreen.nextLevel('agencies'), 'fpaps');
    expect(GaaChildrenScreen.nextLevel('expenses'), isNull);
    expect(GaaChildrenScreen.canDrillDeeper('fund_subcategories'), isTrue);
    expect(GaaChildrenScreen.canDrillDeeper('expenses'), isFalse);
    expect(GaaChildrenScreen.levelName('fpaps'), 'Programs (P/A/P)');
  });

  test('the browser data ranks departments for a year and counts lines', () {
    expect(_national.sortedFor(2026).map((row) => row.id), ['18', '07']);
    expect(_national.sortedFor(2025).map((row) => row.id), ['18', '07']);
    expect(_national.lineItemsFor(2026), 20);
    expect(_national.totalFor(2026), 1000);
  });

  testWidgets('the year strip shows only the years the API reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: YearStrip(
            totals: const {2020: 1, 2027: 2},
            selected: 2027,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('2020'), findsOneWidget);
    expect(find.text('2027'), findsOneWidget);
    expect(find.text('2026'), findsNothing);
    expect(sortedYearKeys(const {2027: 1, 2020: 2}), [2020, 2027]);
  });

  testWidgets('the GAA browser home renders the remote year list', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2020'), findsNothing);
  });

  testWidgets('the GAA browser lists departments and links to the region page', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('GAA budgets'), findsOneWidget);
    expect(find.text('Enacted 2020–2026 · exact pesos'), findsOneWidget);
    expect(
      find.text('Department of Public Works and Highways (DPWH)'),
      findsOneWidget,
    );
    expect(find.text('Department of Education (DepEd)'), findsOneWidget);
    expect(find.text('2 departments with money in 2026'), findsOneWidget);
    expect(find.text('Where the money lands: GAA by region'), findsOneWidget);
  });

  testWidgets('the browser search narrows the department list', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'education');
    await tester.pump();

    expect(find.text('1 department with money in 2026'), findsOneWidget);
    expect(find.text('Department of Education (DepEd)'), findsOneWidget);
    expect(
      find.text('Department of Public Works and Highways (DPWH)'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), 'nowhere');
    await tester.pump();

    expect(find.text('No department matches'), findsOneWidget);
  });

  testWidgets('a department opens its own page with agencies and classes', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(
      find.text('Department of Public Works and Highways (DPWH)'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office of the Secretary'), findsOneWidget);
    expect(find.text('Personnel Services'), findsOneWidget);
    expect(find.text('Capital Outlays'), findsOneWidget);
    expect(find.text('Drill the FY 2026 breakdown'), findsOneWidget);
  });

  testWidgets('an agency drills into its programs', (tester) async {
    await _open(tester, location: '/gaa/2026/departments/18');

    await tester.tap(find.text('Office of the Secretary'));
    await tester.pumpAndSettle();

    expect(find.text('Office of the Secretary'), findsOneWidget);
    expect(find.text('Programs (P/A/P) · FY 2026'), findsOneWidget);
    expect(find.text('Roads'), findsOneWidget);
  });

  testWidgets('the year page shows every department with its share', (
    tester,
  ) async {
    await _open(tester, location: '/gaa/2026');

    expect(find.text('FY 2026 GAA'), findsOneWidget);
    expect(find.text('42 line items across 2 departments'), findsOneWidget);
    expect(find.text('70.0%'), findsOneWidget);
    expect(find.text('30.0%'), findsOneWidget);
  });

  testWidgets('the regional page separates named regions from unknown money', (
    tester,
  ) async {
    await _open(tester, location: '/gaa/regional');

    expect(find.text('GAA by region'), findsOneWidget);
    expect(find.text('National Capital Region (NCR)'), findsOneWidget);
    expect(find.text('90.0%'), findsOneWidget);
    expect(find.text('Region Unknown'), findsNothing);
    expect(find.text('₱100 on no named region'), findsOneWidget);
  });

  testWidgets('the budget app bar opens the GAA browser first', (
    tester,
  ) async {
    await _open(tester, location: '/');

    final gaa = tester.getTopLeft(find.byTooltip('GAA budgets'));
    final inserted = tester.getTopLeft(find.byTooltip('Inserted projects'));
    final about = tester.getTopLeft(find.byTooltip('About this app'));
    expect(gaa.dx, lessThan(inserted.dx));
    expect(inserted.dx, lessThan(about.dx));

    await tester.tap(find.byTooltip('GAA budgets'));
    await tester.pumpAndSettle();

    expect(find.text('GAA budgets'), findsOneWidget);
    expect(find.text('Enacted 2020–2026 · exact pesos'), findsOneWidget);
  });
}
