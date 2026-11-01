import 'package:url_launcher/url_launcher.dart';

Future<void> openExternal(String? url) async {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null) return;
  if (uri.scheme != 'https' && uri.scheme != 'http') return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
