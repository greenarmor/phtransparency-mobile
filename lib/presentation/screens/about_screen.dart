import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_status.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/links.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../data/models/place.dart';
import '../../data/services/scope_service.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final place = ref.watch(placeProvider);
    final scope = ref.watch(scopeProvider);
    final result = scope.asData?.value;
    final notice = ref.watch(overviewProvider).asData?.value.meta.notice;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            place.title,
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(place.subtitle, style: AppTheme.meta(context, size: 12.5)),
          const SizedBox(height: 16),
          _ScopeCard(place: place, result: result, loading: scope.isLoading),
          if (result?.note != null) ...[
            const SizedBox(height: 10),
            NoteCard(
              title: 'Reading this view',
              body: result!.note!,
              tint: colors.neutral,
            ),
          ],
          if (result?.truncated ?? false) ...[
            const SizedBox(height: 10),
            NoteCard(
              title: 'This view is capped',
              body:
                  'The API returned more rows than one view should hold, so the '
                  'list stops at 4,000 lines. Narrow the place to see the rest.',
              icon: Icons.warning_amber_outlined,
              tint: colors.neutral,
            ),
          ],
          if (result != null && result.disclaimers.isNotEmpty) ...[
            const SectionHeading(title: 'How to read this view'),
            for (final disclaimer in result.disclaimers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: NoteCard(
                  title: disclaimer.title,
                  body: disclaimer.body,
                  icon: Icons.gavel_outlined,
                ),
              ),
          ],
          const SectionHeading(title: 'About the app'),
          Text(
            'A mobile view of the BetterGov.ph budget transparency portal for '
            'every place in the Philippines: FY ${AppConfig.fiscalYear} '
            'projects in the NEP and the House bill, with the page each figure '
            'is on, and the enacted budgets 2020–2026.',
            style: AppTheme.meta(context, size: 13),
          ),
          const SizedBox(height: 12),
          AsyncView<Overview>(
            value: ref.watch(overviewProvider),
            loadingLabel: 'Reading the source notes…',
            onRetry: () => ref.invalidate(overviewProvider),
            builder: (context, overview) => _FactsCard(overview: overview),
          ),
          const SizedBox(height: 10),
          if (ref.watch(firebaseEnabledProvider))
            const NoteCard(
              title: 'Usage events and crash reports',
              body:
                  'Opening a project or a tab records an anonymous event, and a '
                  'crash sends a report, both to Firebase. The app has no account, '
                  'no location access, no ads and no tracking beyond those events.',
              icon: Icons.privacy_tip_outlined,
            )
          else
            const NoteCard(
              title: 'No usage tracking',
              body:
                  'This version records no usage events and sends no crash '
                  'reports. The app has no account, no location access, no ads '
                  'and no tracking.',
              icon: Icons.privacy_tip_outlined,
            ),
          const SectionHeading(title: 'Rules this app keeps'),
          const _BulletCard(rules: _appRules),
          const SizedBox(height: 10),
          AsyncView<Overview>(
            value: ref.watch(overviewProvider),
            loadingLabel: 'Reading the API’s rules…',
            onRetry: () => ref.invalidate(overviewProvider),
            builder: (context, overview) => overview.rules.isEmpty
                ? const SizedBox.shrink()
                : _BulletCard(
                    title: 'Rules the API publishes, word for word',
                    rules: overview.rules,
                  ),
          ),
          if (notice != null && notice.isNotEmpty) ...[
            const SectionHeading(title: 'Published notice'),
            NoteCard(
              title: 'From the API',
              body: notice,
              icon: Icons.verified_outlined,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Built on the public BetterGov.ph Budget API. '
            'Independent and unofficial.',
            style: AppTheme.meta(context, size: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.place,
    required this.result,
    required this.loading,
  });

  final PlaceSelection place;
  final ScopeResult? result;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lines = result?.summary.rows;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This view',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            _Row('Scope', placeKindLabel(place)),
            _Row('What is counted', placeScopeDescription(place)),
            _Row(
              'Project lines',
              place is NationalPlace
                  ? 'Nationwide totals, read on the home page'
                  : lines == null
                  ? (loading ? 'Reading…' : dash)
                  : plural(lines, 'line'),
            ),
            _Row(
              'Programs',
              '${AppConfig.datasets.length} · DPWH, farm-to-market roads, '
                  'health facilities, irrigation',
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final meta = overview.meta;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row('Version', AppConfig.appVersion),
            _Row('Budget API', AppConfig.apiBase),
            _Row('Comparison source', AppConfig.sourceRepo),
            _Row('Source commit', _shortCommit(meta.sourceCommit)),
            _Row('Built', shortDate(meta.builtAt)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => openExternal(AppConfig.sourceUrl),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open the portal'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openExternal(AppConfig.docsUrl),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text('API docs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.rules, this.title});

  final List<String> rules;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (final rule in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check, size: 14, color: colors.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: colors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: AppTheme.meta(context, size: 12)),
          ),
          Expanded(
            child: Text(
              value ?? dash,
              style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortCommit(String? commit) {
  if (commit == null || commit.length < 8) return commit ?? dash;
  return commit.substring(0, 8);
}

const _appRules = <String>[
  'Amounts are integer pesos as published. A dash means the document has no '
      'such line, never zero.',
  'The NEP and the House bill are compared, never added: they are two versions '
      'of one budget.',
  'A line found in one version only is a candidate, never a confirmed '
      'insertion or deletion.',
  'A DPWH office that serves several districts is shown whole; its money is '
      'never split between them.',
  'Names are matched, not places surveyed: a line whose title never spells the '
      'place out will not appear under a name search.',
  'The GAA is enacted for the whole country, so the GAA tab shows the '
      'national budgets rather than a region\'s slice.',
];
