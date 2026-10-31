import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/budget_models.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About the data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            AppConfig.appName,
            style: const TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A mobile view of the BetterGov.ph budget transparency portal, for '
            'every place in the Philippines. Browse all 254 legislative '
            'districts, every region, or search any city, municipality or '
            'province by name: FY ${AppConfig.fiscalYear} projects in the NEP '
            'and the House bill, with the page each figure is on, and the '
            'enacted budgets 2020–2026.',
            style: AppTheme.meta(size: 13),
          ),
          const SizedBox(height: 18),
          AsyncView<Overview>(
            value: overview,
            loadingLabel: 'Reading the source notes…',
            onRetry: () => ref.invalidate(overviewProvider),
            builder: (context, data) => _OverviewBody(overview: data),
          ),
          const SectionHeading(title: 'Where the numbers come from'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row('API', AppConfig.apiBase),
                  const Divider(height: 18),
                  _Row(
                    'Source of the comparison',
                    'github.com/csiiiv/DPWH-NEP-HB-2027-ANALYSIS',
                  ),
                  const Divider(height: 18),
                  const Text(
                    'The 2027 figures are an independent reading of the '
                    'published NEP and House Bill 10858, republished through '
                    'the BetterGov.ph Budget API. The enacted budgets 2020–2026 '
                    'are the DBM General Appropriations Acts.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppTheme.ink2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _open(AppConfig.sourceUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open the national portal'),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeading(title: 'Rules this app keeps'),
          for (final rule in _defaultRules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.ruleSoft),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.check,
                        size: 15,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppTheme.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SectionHeading(title: 'Reporting'),
          const NoteCard(
            title: 'Coming to budget.bettergov.ph',
            body:
                'Citizen reports will go to one central service for every '
                'portal. This app will link to it with the project reference; '
                'it does not collect reports itself.',
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 18),
          Text(
            'Built on the public BetterGov.ph Budget API. '
            'Independent and unofficial.',
            style: AppTheme.meta(size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final meta = overview.meta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The dataset',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  overview.summary,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppTheme.ink2,
                  ),
                ),
                const Divider(height: 22),
                _Row('Source commit', _shortCommit(meta.sourceCommit)),
                _Row('Built', meta.builtAt),
              ],
            ),
          ),
        ),
        const SectionHeading(title: 'The API’s own rules'),
        for (final rule in overview.rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NoteCard(title: '', body: rule),
          ),
        if (overview.disclaimers.isNotEmpty) ...[
          const SectionHeading(title: 'Notices'),
          for (final disclaimer in overview.disclaimers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                title: disclaimer.title,
                body: disclaimer.body,
                icon: Icons.gavel_outlined,
              ),
            ),
        ],
        if (meta.notice.isNotEmpty) ...[
          const SizedBox(height: 8),
          NoteCard(
            title: 'Published notice',
            body: meta.notice,
            icon: Icons.verified_outlined,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTheme.meta(size: 12)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortCommit(String? commit) {
  if (commit == null || commit.length < 8) return commit ?? '-';
  return commit.substring(0, 8);
}

const _defaultRules = <String>[
  'Amounts are integer pesos as published. A dash means the document has no '
      'such line, never zero.',
  'The NEP and the House bill are two versions of one budget: compared, never '
      'added.',
  '"In the House bill only" and "in the NEP only" are candidates: leads to '
      'check, not confirmed insertions or deletions.',
  'A DPWH office that serves several districts is shown whole; its money is '
      'never split between them.',
  'Enacted amounts are appropriations: the authority to spend, not spending.',
  'Nothing is hidden silently: exclusions carry reasons and are published.',
  'Disclaimers are printed from the API response itself, so their wording '
      'cannot drift.',
];

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
