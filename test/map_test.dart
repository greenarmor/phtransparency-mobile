import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/data/services/scope_service.dart';
import 'package:bettergov_budget/presentation/widgets/scope_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectRow _row({
  String id = 'leg:test',
  double? lat,
  double? lon,
  int? house,
  int? nep,
  String group = 'unchanged',
  String title = 'Test line',
}) => ProjectRow(
  id: id,
  dataset: 'dpwh',
  title: title,
  program: 'DPWH',
  pap: null,
  office: null,
  region: 'Region VII',
  regionKey: 'VII',
  statusLabel: 'Same amount in both',
  bridgeGroup: group,
  groupLabel: 'Same amount in both',
  held: false,
  nepPhp: nep,
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
  lat: lat,
  lon: lon,
);

ScopedProject _point({
  required String id,
  double lat = 10,
  double lon = 123,
  int? house,
  String group = 'unchanged',
  String title = 'Test line',
}) => ScopedProject(
  project: _row(
    id: id,
    lat: lat,
    lon: lon,
    house: house,
    group: group,
    title: title,
  ),
);

void main() {
  test('rows without usable coordinates are not mappable', () {
    expect(_row().hasCoordinates, isFalse);
    expect(_row(lat: 10, lon: 123).hasCoordinates, isTrue);
    expect(_row(lat: 91, lon: 123).hasCoordinates, isFalse);
    expect(_row(lat: 10, lon: 181).hasCoordinates, isFalse);
    expect(_row(lat: double.nan, lon: 123).hasCoordinates, isFalse);
  });

  test('only coordinate rows reach the map, largest amount first', () {
    final points = mappableProjects([
      _point(id: 'a', house: 1000),
      ScopedProject(project: _row(id: 'b')),
      _point(id: 'c', house: 5000),
    ]);

    expect(points.map((p) => p.project.id), ['c', 'a']);
  });

  test('the map respects the status filter and the search text', () {
    final all = [
      _point(
        id: 'a',
        house: 10,
        group: 'house_only',
        title: 'Bridge at Carmen',
      ),
      _point(id: 'b', house: 20, group: 'unchanged', title: 'Road at Carmen'),
      _point(id: 'c', house: 30, group: 'unchanged', title: 'Road at Bohol'),
    ];

    expect(mappableProjects(all, group: 'unchanged').map((p) => p.project.id), [
      'c',
      'b',
    ]);
    expect(mappableProjects(all, query: 'carmen').map((p) => p.project.id), [
      'b',
      'a',
    ]);
    expect(mappableProjects(all, group: 'unchanged', query: 'bohol').length, 1);
  });

  testWidgets('the map renders and survives a missing tile network', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ScopeMap(
              points: [_point(id: 'a', house: 1000)],
              height: 220,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('tapping a dot labels it and can open the line', (tester) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ScopeMap(
              points: [_point(id: 'a', house: 1000)],
              height: 300,
              interactive: true,
              onPointTap: (item) => opened = item.project.id,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('map-dot-a')));
    await tester.pump();

    expect(find.text('Test line'), findsWidgets);
    expect(opened, isNull);

    await tester.tap(find.text('Open line'));
    await tester.pump();

    expect(opened, 'a');
  });

  testWidgets('the preview callout labels the pin without an action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ScopeMap(
              points: [_point(id: 'a', house: 2500000)],
              height: 300,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('map-dot-a')));
    await tester.pump();

    expect(find.text('Test line'), findsWidgets);
    expect(find.textContaining('₱2.5M'), findsWidgets);
    expect(find.text('Open line'), findsNothing);
  });

  testWidgets('an empty map says so instead of showing a blank canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScopeMap(points: [], height: 220)),
      ),
    );
    await tester.pump();

    expect(
      find.text('No line in this view publishes coordinates.'),
      findsOneWidget,
    );
  });
}
