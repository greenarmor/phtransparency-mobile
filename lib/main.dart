import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firebase/firebase_status.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_providers.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final firebase = await _startFirebase();
  runApp(
    ProviderScope(
      overrides: [firebaseEnabledProvider.overrideWithValue(firebase)],
      child: const BetterGovBudgetApp(),
    ),
  );
}

/// Firebase is optional. The options come from the platform config a clone
/// brings itself (`android/app/google-services.json`,
/// `ios/Runner/GoogleService-Info.plist`); without it initialisation throws,
/// the app runs with Analytics and Crashlytics off, and nothing else changes.
///
/// Returns whether Firebase started, so the About page can say what this build
/// does.
Future<bool> _startFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return false;
  }
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Started, but the collection switches could not be set; the platform
    // defaults apply, so the build still counts as having Firebase.
  }
  return true;
}

class BetterGovBudgetApp extends ConsumerWidget {
  const BetterGovBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'BetterGov Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: router,
    );
  }
}
