import 'package:bettergov_budget/presentation/widgets/hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _card(Brightness brightness) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: const Scaffold(
    body: Padding(
      padding: EdgeInsets.all(16),
      child: HeroCard(child: Text('NEP ₱1.00B')),
    ),
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the hero card stands upright in ${brightness.name} mode', (
      tester,
    ) async {
      await tester.pumpWidget(_card(brightness));

      expect(tester.takeException(), isNull);
      expect(find.text('NEP ₱1.00B').hitTestable(), findsOneWidget);

      // No tilt, skew or rotation anywhere inside the card.
      final transforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(HeroCard),
          matching: find.byType(Transform),
        ),
      );
      for (final transform in transforms) {
        expect(transform.transform.isIdentity(), isTrue);
      }
      expect(
        find.descendant(
          of: find.byType(HeroCard),
          matching: find.byType(RotatedBox),
        ),
        findsNothing,
      );
    });
  }

  testWidgets('the hero card has the same shape in light and dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(_card(Brightness.light));
    final lightCard = tester.getRect(find.byType(HeroCard));
    final lightText = tester.getRect(find.text('NEP ₱1.00B'));

    await tester.pumpWidget(_card(Brightness.dark));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(HeroCard)), lightCard);
    expect(tester.getRect(find.text('NEP ₱1.00B')), lightText);
  });

  testWidgets('the hero card keeps a big type scale readable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroEyebrow('FY 2027 · THE WHOLE COUNTRY'),
                      SizedBox(height: 12),
                      Text(
                        '₱620.99B',
                        style: TextStyle(fontSize: 26, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('FY 2027 · THE WHOLE COUNTRY'), findsOneWidget);
  });
}
