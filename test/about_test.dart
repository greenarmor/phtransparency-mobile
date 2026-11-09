import 'package:bettergov_budget/core/config/app_config.dart';
import 'package:bettergov_budget/core/firebase/firebase_status.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/data/models/place.dart';
import 'package:bettergov_budget/data/services/scope_service.dart';
import 'package:bettergov_budget/presentation/screens/about_screen.dart';
import 'package:bettergov_budget/providers/budget_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Overview _overview({List<String> rules = const ['A published rule']}) =>
    Overview(
      title: 'FY2027 House bill against the NEP',
      summary: 'Every project line set against the NEP.',
      rules: rules,
      disclaimers: const [
        Disclaimer(
          id: 'disclaimer-no-allegations',
          title: 'No allegations.',
          body: 'A candidate is a lead for checking.',
        ),
      ],
      meta: const BudgetMeta(
        dataset: 'hgab',
        notice: 'Published notice.',
        sourceCommit: 'a0caa778442cdae5583f5a006ea7401dab00e5ac',
        builtAt: '2026-10-26T08:46:14.383Z',
      ),
      datasets: [],
    );

ScopeResult _scope({
  required String? note,
  List<Disclaimer> disclaimers = const [],
  bool national = false,
}) => ScopeResult(
  projects: const [],
  disclaimers: disclaimers,
  summary: Summary.of(const []),
  meta: null,
  truncated: false,
  national: national,
  note: note,
);

class _FixedPlace extends PlaceController {
  _FixedPlace(this.place);

  final PlaceSelection place;

  @override
  PlaceSelection build() => place;
}

Future<void> _pump(
  WidgetTester tester, {
  required PlaceSelection place,
  required ScopeResult scope,
  bool firebase = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseEnabledProvider.overrideWithValue(firebase),
        placeProvider.overrideWith(() => _FixedPlace(place)),
        scopeProvider.overrideWith((ref) async => scope),
        overviewProvider.overrideWith((ref) async => _overview()),
      ],
      child: const MaterialApp(home: AboutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('each place kind names its own scope', () {
    expect(placeKindLabel(const NationalPlace()), 'Nationwide totals');
    expect(
      placeKindLabel(const RegionPlace(key: 'VII', label: 'VII')),
      'One DPWH region',
    );
    expect(
      placeKindLabel(
        const DistrictPlace(
          id: 'leg:bohol:2nd',
          label: 'Bohol',
          jurisdiction: 'Bohol',
        ),
      ),
      'Legislative district',
    );
    expect(
      placeKindLabel(const NamedPlace(q: 'carmen', label: 'Carmen')),
      contains('named'),
    );
  });

  test('the scope description differs per place', () {
    final district = placeScopeDescription(
      const DistrictPlace(
        id: 'leg:bohol:2nd',
        label: 'Bohol',
        jurisdiction: 'Bohol',
      ),
    );
    expect(district, contains('office'));
    expect(
      placeScopeDescription(const NationalPlace()),
      contains('every region'),
    );
  });

  testWidgets('a district view says what it counts', (tester) async {
    await _pump(
      tester,
      place: const DistrictPlace(
        id: 'leg:bohol:2nd',
        label: 'Bohol, 2nd District',
        jurisdiction: 'Bohol',
      ),
      scope: _scope(
        note: 'A shared office total is shown whole.',
        disclaimers: const [
          Disclaimer(
            id: 'disclaimer-offices',
            title: 'Office and legislative-district associations.',
            body: 'Shared totals are never split.',
          ),
        ],
      ),
    );

    expect(find.text('Bohol, 2nd District'), findsOneWidget);
    expect(find.text('Legislative district'), findsOneWidget);
    expect(find.text('A shared office total is shown whole.'), findsOneWidget);
    expect(
      find.text('Office and legislative-district associations.'),
      findsOneWidget,
    );
  });

  testWidgets('a build without Firebase says it records nothing', (
    tester,
  ) async {
    await _pump(
      tester,
      place: const NationalPlace(),
      scope: _scope(note: null, national: true),
    );

    await tester.scrollUntilVisible(find.text('No usage tracking'), 300);
    expect(find.text('No usage tracking'), findsOneWidget);
    expect(find.text('Usage events and crash reports'), findsNothing);
    expect(find.textContaining('records no usage events'), findsOneWidget);
  });

  testWidgets('a build with Firebase discloses its events and reports', (
    tester,
  ) async {
    await _pump(
      tester,
      place: const NationalPlace(),
      scope: _scope(note: null, national: true),
      firebase: true,
    );

    await tester.scrollUntilVisible(
      find.text('Usage events and crash reports'),
      300,
    );
    expect(find.text('Usage events and crash reports'), findsOneWidget);
    expect(find.text('No usage tracking'), findsNothing);
    expect(find.textContaining('to Firebase'), findsOneWidget);
  });

  testWidgets('the About page shows the app version', (tester) async {
    await _pump(
      tester,
      place: const NationalPlace(),
      scope: _scope(note: null, national: true),
    );

    expect(find.text(AppConfig.appVersion), findsOneWidget);
  });

  testWidgets('a region view does not claim district content', (tester) async {
    await _pump(
      tester,
      place: const RegionPlace(
        key: 'VII',
        label: 'Region VII',
        name: 'Central Visayas',
      ),
      scope: _scope(note: 'Farm-to-market roads are not published by region.'),
    );

    expect(find.text('One DPWH region'), findsOneWidget);
    expect(find.text('Legislative district'), findsNothing);
    expect(
      find.text('Farm-to-market roads are not published by region.'),
      findsOneWidget,
    );
  });
}
