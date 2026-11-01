import 'package:bettergov_budget/presentation/widgets/status_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _counts = <String, int>{
  'house_only': 6954,
  'nep_only': 1784,
  'unchanged': 11148,
  'increased': 243,
  'decreased': 265,
  'scope_review': 37,
};

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 360, child: child)),
      ),
    ),
  ),
);

void main() {
  testWidgets('every tile paints at large text without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const StatusGrid(counts: _counts)));
    expect(tester.takeException(), isNull);
    expect(find.text('House only'), findsOneWidget);

    await tester.pumpWidget(
      _app(const StatusGrid(counts: _counts), textScale: 1.3),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Scope review'), findsOneWidget);
  });

  testWidgets('tapping a tile selects it and tapping again clears it', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => StatusGrid(
            counts: _counts,
            selected: selected,
            onSelected: (group) => setState(() => selected = group),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Same'));
    await tester.pump();
    expect(selected, 'unchanged');

    await tester.tap(find.text('Same'));
    await tester.pump();
    expect(selected, isNull);
  });
}
