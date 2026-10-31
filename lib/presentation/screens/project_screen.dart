import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/budget_models.dart';
import '../../providers/budget_providers.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.dataset, required this.id});

  final String dataset;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(projectDetailProvider(ProjectArgs(dataset, id)));
    final project = detail.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        actions: [
          if (project != null)
            IconButton(
              tooltip: 'Open on budget.bettergov.ph',
              onPressed: () => _open(project.row.url),
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: AsyncView<ProjectDetail>(
        value: detail,
        loadingLabel: 'Reading this project…',
        onRetry: () =>
            ref.invalidate(projectDetailProvider(ProjectArgs(dataset, id))),
        builder: (context, value) => _Detail(detail: value),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final ProjectDetail detail;

  @override
  Widget build(BuildContext context) {
    final row = detail.row;
    final pages = <String, int?>{
      'NEP': row.nepPage,
      'House bill, 2R': row.hgab2Page,
      'House bill, 3R': row.hgab3Page,
    };
    final amounts = <String, int?>{
      'NEP': row.nepPhp,
      'House bill, 2R': row.hgab2Php,
      'House bill, 3R': row.hgab3Php,
    };
    final pdfs = <String, String?>{
      'NEP': row.pdfUrl['nep'],
      'House bill, 2R': row.pdfUrl['hgab2'],
      'House bill, 3R': row.pdfUrl['hgab3'],
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            StatusPill(
              group: row.bridgeGroup,
              label: groupTitles[row.bridgeGroup] ?? row.statusLabel,
              held: row.held,
            ),
            if (row.held) ...[
              const SizedBox(width: 8),
              Text('unconfirmed match', style: AppTheme.meta(size: 11.5)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          row.title,
          style: const TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        MetaLine(children: [row.office, row.program, row.pap]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amount in each version',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A dash means the document has no such line, never zero.',
                  style: AppTheme.meta(size: 11.5),
                ),
                const SizedBox(height: 6),
                for (final entry in amounts.entries)
                  _AmountRow(
                    label: entry.key,
                    amount: entry.value,
                    page: pages[entry.key],
                    pdfUrl: pdfs[entry.key],
                  ),
                if (row.deltaPhp != null) ...[
                  const Divider(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Change, House bill vs NEP',
                            style: AppTheme.meta(size: 12.5),
                          ),
                        ),
                        Text(
                          signedCompactPeso(row.deltaPhp),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: row.deltaPhp! >= 0
                                ? AppTheme.positive
                                : AppTheme.negative,
                            fontFeatures: AppTheme.amount.fontFeatures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How the versions were matched',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _LabelRow('Pairing', detail.matchLabel),
                _LabelRow('Reading', detail.readingLabel),
                _LabelRow('DPWH site', detail.dpwhSiteLabel),
                _LabelRow('Zone', detail.zoneLabel),
                _LabelRow(
                  'Confidence',
                  detail.confidence == null
                      ? null
                      : '${(detail.confidence! * 100).round()}%',
                ),
                if (detail.flagLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final flag in detail.flagLabels)
                        Chip(
                          label: Text(
                            flag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Pairings are candidates: leads for checking, not confirmed '
                  'insertions or deletions. The amount is the one the documents '
                  'publish, on the page beside it.',
                  style: AppTheme.meta(size: 11.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Provenance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                _LabelRow('Dataset', row.dataset.toUpperCase()),
                _LabelRow('Line id', row.id),
                _LabelRow('Region', row.region),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _open(row.url),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View on budget.bettergov.ph'),
                      ),
                    ),
                  ],
                ),
                if (row.pdfUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _open(row.pdfUrl.values.first),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                          ),
                          label: const Text('Open source PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const NoteCard(
          title: 'A candidate, not a finding',
          body:
              'An insertion, deletion or amount-change candidate describes a '
              'provisional comparison between identified sources. It does not '
              'establish irregularity or wrongdoing.',
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.page,
    required this.pdfUrl,
  });

  final String label;
  final int? amount;
  final int? page;
  final String? pdfUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: AppTheme.meta(size: 12.5)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              compactPeso(amount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: amount == null ? AppTheme.inkMute : AppTheme.ink,
                fontFeatures: AppTheme.amount.fontFeatures,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: pdfUrl == null
                ? Text(
                    page == null ? dash : 'Page $page',
                    textAlign: TextAlign.right,
                    style: AppTheme.meta(size: 11.5),
                  )
                : TextButton(
                    onPressed: () => _open(pdfUrl),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      page == null ? 'Open' : 'Page $page',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: AppTheme.meta(size: 12)),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.ink2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _open(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
