import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> logProjectOpen({
  required String dataset,
  required String id,
}) async {
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'project_open',
      parameters: {'dataset': dataset, 'line_id': id},
    );
  } catch (_) {
    return;
  }
}

Future<void> logTabOpen(String tab) async {
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'tab_open',
      parameters: {'tab': tab},
    );
  } catch (_) {
    return;
  }
}
