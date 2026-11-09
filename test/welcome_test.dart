import 'package:bettergov_budget/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('budget home')),
      ),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

Future<void> _phone(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(_app());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 550));
}

void main() {
  testWidgets('the welcome screen shows the logo, message and disclaimer', (
    tester,
  ) async {
    await _phone(tester);
    await _open(tester);

    expect(find.text('BetterGov.Ph'), findsOneWidget);
    expect(find.text('WE ARE'), findsOneWidget);
    expect(find.text('NOT'), findsOneWidget);
    expect(find.text('IGNORANT'), findsOneWidget);
    expect(
      find.text(
        'Inserted and adjusted projects in the 2027 House budget bill. '
        'We read every single one.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'DPWH, farm-to-market roads, health facilities and irrigation. '
        'Inserted first, then increased, then decreased, largest first. '
        'DEO: district engineering office, the DPWH unit that carries out '
        'projects in its area. Its number is its own and need not match the '
        'legislative district it serves.',
      ),
      findsOneWidget,
    );
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Light'), findsNothing);
    expect(find.text('Dark'), findsNothing);
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Continue to the budget'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('the countdown ticks down from thirty seconds', (tester) async {
    await _phone(tester);
    await _open(tester);

    expect(
      find.text('Opening the budget automatically in 30 s'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    expect(
      find.text('Opening the budget automatically in 27 s'),
      findsOneWidget,
    );
  });

  testWidgets('the welcome screen opens the budget by itself after 30 s', (
    tester,
  ) async {
    await _phone(tester);
    await _open(tester);

    expect(find.text('budget home'), findsNothing);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();

    expect(find.text('budget home'), findsOneWidget);
  });

  testWidgets('continuing early leaves before the countdown ends', (
    tester,
  ) async {
    await _phone(tester);
    await _open(tester);

    await tester.ensureVisible(find.text('Continue to the budget'));
    await tester.tap(find.text('Continue to the budget'));
    await tester.pumpAndSettle();

    expect(find.text('budget home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the fist sits inside the hero and leaves a clear margin', (
    tester,
  ) async {
    await _phone(tester);
    await _open(tester);

    final hero = tester.getRect(
      find
          .ancestor(of: find.text('WE ARE'), matching: find.byType(Stack))
          .first,
    );
    final fist = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('campaign_fist'),
      ),
    );

    expect(fist.left, greaterThan(hero.left));
    expect(fist.top, greaterThan(hero.top));
    expect(fist.right, lessThan(hero.right));
    expect(fist.bottom, lessThan(hero.bottom));
  });

  testWidgets('the welcome screen survives a small screen and big text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _app(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));

    expect(tester.takeException(), isNull);
    expect(find.text('Continue to the budget'), findsOneWidget);
  });
}
