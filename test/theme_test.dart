import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/presentation/widgets/app_logo.dart';
import 'package:bettergov_budget/providers/theme_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a saved choice is restored and written back', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await container.read(themeModeProvider.notifier).select(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('an unknown saved value falls back to following the system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('light and dark palettes differ and both expose their extension', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.extension<AppColors>(), AppColors.light);
    expect(dark.extension<AppColors>(), AppColors.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);

    expect(AppColors.light.paper, const Color(0xFFF3EFE4));
    expect(AppColors.dark.paper, isNot(AppColors.light.paper));
    expect(AppColors.dark.ink, isNot(AppColors.light.ink));
  });

  testWidgets('the logo falls back to a white plate until a dark mark exists', (
    tester,
  ) async {
    Widget wrap(Brightness brightness) => MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: const Scaffold(
        body: AppLogo(asset: 'assets/images/welcome_logo.png', size: 120),
      ),
    );

    await tester.pumpWidget(wrap(Brightness.dark));
    await tester.pump();
    final plate = tester.widget<Container>(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(Container))
          .first,
    );
    expect(plate.decoration, isA<BoxDecoration>());
    expect((plate.decoration! as BoxDecoration).color, Colors.white);

    await tester.pumpWidget(wrap(Brightness.light));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a real dark mark is drawn without the plate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: AppLogo(
            asset: 'assets/images/welcome_logo.png',
            darkAsset: 'assets/images/welcome_logo_dark.png',
            size: 120,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Container), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('the palette follows the theme inside a widget', (tester) async {
    late AppColors seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            seen = context.colors;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen, AppColors.dark);
  });
}
