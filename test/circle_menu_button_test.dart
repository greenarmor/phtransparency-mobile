import 'package:bettergov_budget/presentation/widgets/circle_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  required Future<void> Function() onOpen,
  bool reduceMotion = false,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(child: CircleMenuButton(onOpen: onOpen)),
  ),
);

void main() {
  testWidgets('the menu opens right away, while the circle turns', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(_app(onOpen: () async => opens++));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell));
    await tester.pump(const Duration(milliseconds: 60));

    expect(opens, 0);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(find.byIcon(Icons.travel_explore), findsOneWidget);
  });

  testWidgets('the menu opens while the circle is still turning', (
    tester,
  ) async {
    var openedAfter = const Duration(days: 1);
    late DateTime tapAt;
    await tester.pumpWidget(
      _app(
        onOpen: () async {
          openedAfter = tester.binding.clock.now().difference(tapAt);
        },
      ),
    );
    await tester.pumpAndSettle();

    tapAt = tester.binding.clock.now();
    await tester.tap(find.byType(InkWell));
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(openedAfter.inMilliseconds, greaterThan(40));
    expect(openedAfter.inMilliseconds, lessThan(160));
  });

  testWidgets('taps during the animation are ignored', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(
        onOpen: () async {
          opens++;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byType(InkWell), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 40));

    await tester.pumpAndSettle();
    expect(opens, 1);
  });

  testWidgets('reduced motion opens the menu without waiting', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      _app(reduceMotion: true, onOpen: () async => opens++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(opens, 1);
  });
}
