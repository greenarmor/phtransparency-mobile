import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this build started Firebase, which only happens when the platform
/// config (`google-services.json`, `GoogleService-Info.plist`) was bundled.
///
/// Analytics and Crashlytics exist only then, so the About page uses this to
/// describe what the running build really does. `main` overrides it with the
/// start-up result; it is false everywhere else, tests included.
final firebaseEnabledProvider = Provider<bool>((ref) => false);
