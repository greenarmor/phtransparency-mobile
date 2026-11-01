import 'package:bettergov_budget/presentation/widgets/hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the hero card tilts its surface without clipping content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: HeroCard(child: Text('NEP ₱1.00B')),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('NEP ₱1.00B'), findsOneWidget);
    expect(find.text('NEP ₱1.00B').hitTestable(), findsOneWidget);
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
