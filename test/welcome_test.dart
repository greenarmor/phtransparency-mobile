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
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
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
