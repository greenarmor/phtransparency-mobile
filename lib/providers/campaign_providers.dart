import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/budget_models.dart';
import 'budget_providers.dart';

class CampaignDataset {
  const CampaignDataset({
    required this.key,
    required this.short,
    required this.label,
    required this.addedRows,
    required this.addedPhp,
  });

  final String key;
  final String short;
  final String label;
  final int addedRows;
  final int addedPhp;
}

/// The NEP-vs-House-bill change picture for the whole country, read from the
/// same BetterGov API the rest of the app uses (`/api/v1/hgab/2027`).
///
/// The bridge identity, per the API: house_only − nep_only + increased −
/// decreased + scope_review = net_php.
class CampaignSummary {
  const CampaignSummary({
    required this.addedRows,
    required this.addedPhp,
    required this.droppedRows,
    required this.droppedPhp,
    required this.raisedRows,
    required this.raisedPhp,
    required this.loweredRows,
    required this.loweredPhp,
    required this.scopePhp,
    required this.unconfirmedRows,
    required this.datasets,
  });

  final int addedRows;
  final int addedPhp;
  final int droppedRows;
  final int droppedPhp;
  final int raisedRows;
  final int raisedPhp;
  final int loweredRows;
  final int loweredPhp;
  final int scopePhp;
  final int unconfirmedRows;
  final List<CampaignDataset> datasets;

  int get netPhp => addedPhp - droppedPhp + raisedPhp - loweredPhp + scopePhp;

  factory CampaignSummary.of(List<DatasetTotals> datasets) {
    var addedRows = 0;
    var addedPhp = 0;
    var droppedRows = 0;
    var droppedPhp = 0;
    var raisedRows = 0;
    var raisedPhp = 0;
    var loweredRows = 0;
    var loweredPhp = 0;
    var scopePhp = 0;
    var unconfirmedRows = 0;
    final perDataset = <CampaignDataset>[];

    for (final dataset in datasets) {
      final added = dataset.groups['house_only'];
      final dropped = dataset.groups['nep_only'];
      final raised = dataset.groups['increased'];
      final lowered = dataset.groups['decreased'];
      final scope = dataset.groups['scope_review'];

      addedRows += added?.rows ?? 0;
      addedPhp += added?.php ?? 0;
      droppedRows += dropped?.rows ?? 0;
      droppedPhp += dropped?.php ?? 0;
      raisedRows += raised?.rows ?? 0;
      raisedPhp += raised?.php ?? 0;
      loweredRows += lowered?.rows ?? 0;
      loweredPhp += lowered?.php ?? 0;
      scopePhp += scope?.php ?? 0;
      unconfirmedRows += added?.unconfirmedRows ?? 0;

      perDataset.add(
        CampaignDataset(
          key: dataset.key,
          short: dataset.short,
          label: dataset.label,
          addedRows: added?.rows ?? 0,
          addedPhp: added?.php ?? 0,
        ),
      );
    }

    return CampaignSummary(
      addedRows: addedRows,
      addedPhp: addedPhp,
      droppedRows: droppedRows,
      droppedPhp: droppedPhp,
      raisedRows: raisedRows,
      raisedPhp: raisedPhp,
      loweredRows: loweredRows,
      loweredPhp: loweredPhp,
      scopePhp: scopePhp,
      unconfirmedRows: unconfirmedRows,
      datasets: perDataset,
    );
  }
}

bool matchesInsertedQuery(ProjectRow row, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return '${row.title} ${row.office ?? ''} ${row.program ?? ''} '
          '${row.pap ?? ''} ${row.region ?? ''} ${row.dataset}'
      .toLowerCase()
      .contains(needle);
}

List<ProjectRow> filterInsertedProjects(
  Iterable<ProjectRow> rows,
  String query,
) => [
  for (final row in rows)
    if (matchesInsertedQuery(row, query)) row,
];

/// Every House-bill-only line across the four programs, largest House amount
/// first. Fetched once so the inserted-projects page can search in place.
final insertedProjectsProvider = FutureProvider<List<ProjectRow>>((ref) async {
  final api = ref.watch(budgetApiProvider);
  final batches = await Future.wait([
    for (final dataset in AppConfig.datasets)
      api.groupAllRows(dataset, 'house_only'),
  ]);
  final rows = [for (final batch in batches) ...batch];
  rows.sort((a, b) => (b.housePhp ?? 0).compareTo(a.housePhp ?? 0));
  return List.unmodifiable(rows);
});
