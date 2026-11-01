import '../../core/config/app_config.dart';
import '../models/budget_models.dart';
import '../models/place.dart';
import 'budget_api.dart';

class Reason {
  const Reason(this.kind, this.label);

  final String kind;
  final String label;
}

class ScopedProject {
  ScopedProject({required this.project, List<Reason>? reasons})
    : reasons = reasons ?? [];

  final ProjectRow project;
  final List<Reason> reasons;

  String get key => project.key;
}

class GroupCell {
  GroupCell();

  int rows = 0;
  int php = 0;
  int nepPhp = 0;
  int housePhp = 0;
}

class Summary {
  Summary({
    required this.rows,
    required this.nepRows,
    required this.nepPhp,
    required this.houseRows,
    required this.housePhp,
    required this.unconfirmed,
    required this.groups,
  });

  final int rows;
  final int nepRows;
  final int nepPhp;
  final int houseRows;
  final int housePhp;
  final int unconfirmed;
  final Map<String, GroupCell> groups;

  factory Summary.of(Iterable<ProjectRow> rows) {
    var count = 0;
    var nepRows = 0;
    var nepPhp = 0;
    var houseRows = 0;
    var housePhp = 0;
    var unconfirmed = 0;
    final groups = <String, GroupCell>{};

    for (final row in rows) {
      count++;
      if (row.nepPhp != null) {
        nepRows++;
        nepPhp += row.nepPhp!;
      }
      if (row.housePhp != null) {
        houseRows++;
        housePhp += row.housePhp!;
      }
      if (row.held) unconfirmed++;
      final cell = groups.putIfAbsent(row.bridgeGroup, GroupCell.new);
      cell.rows++;
      cell.nepPhp += row.nepPhp ?? 0;
      cell.housePhp += row.housePhp ?? 0;
    }

    return Summary(
      rows: count,
      nepRows: nepRows,
      nepPhp: nepPhp,
      houseRows: houseRows,
      housePhp: housePhp,
      unconfirmed: unconfirmed,
      groups: groups,
    );
  }
}

class ScopeResult {
  const ScopeResult({
    required this.projects,
    required this.disclaimers,
    required this.summary,
    required this.meta,
    required this.truncated,
    required this.national,
    required this.note,
  });

  final List<ScopedProject> projects;
  final List<Disclaimer> disclaimers;
  final Summary summary;
  final BudgetMeta? meta;
  final bool truncated;
  final bool national;
  final String? note;
}

int scopedAmount(ScopedProject item) =>
    item.project.housePhp ?? item.project.nepPhp ?? 0;

List<ScopedProject> mappableProjects(
  Iterable<ScopedProject> projects, {
  String? group,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  final points = projects.where((item) {
    final row = item.project;
    if (!row.hasCoordinates) return false;
    if (group != null && row.bridgeGroup != group) return false;
    if (needle.isEmpty) return true;
    return '${row.title} ${row.office ?? ''} ${row.program ?? ''} ${row.pap ?? ''}'
        .toLowerCase()
        .contains(needle);
  }).toList();
  points.sort((a, b) => scopedAmount(b).compareTo(scopedAmount(a)));
  return points;
}

class _Job {
  const _Job({
    required this.kind,
    required this.label,
    required this.dataset,
    required this.filters,
  });

  final String kind;
  final String label;
  final String dataset;
  final Map<String, dynamic> filters;
}

class ScopeService {
  ScopeService(this._api);

  final BudgetApi _api;

  Future<ScopeResult> load(PlaceSelection place) async {
    switch (place) {
      case NationalPlace():
        return _national();
      case RegionPlace():
        final result = await _fromJobs([
          _Job(
            kind: 'region',
            label: place.title,
            dataset: 'dpwh',
            filters: {'region': place.key},
          ),
        ]);
        return ScopeResult(
          projects: result.projects,
          disclaimers: result.disclaimers,
          summary: result.summary,
          meta: result.meta,
          truncated: result.truncated,
          national: false,
          note:
              'Region totals cover DPWH infrastructure, under the region each '
              'document lists. Farm-to-market roads, health facilities and '
              'irrigation are not published by region in the API.',
        );
      case DistrictPlace():
        return _district(place);
      case NamedPlace():
        return _fromJobs([
          for (final dataset in AppConfig.datasets)
            _Job(
              kind: 'place',
              label: place.q,
              dataset: dataset,
              filters: {'q': place.q},
            ),
        ]);
    }
  }

  Future<ScopeResult> _national() async {
    final overview = await _api.overview();
    return ScopeResult(
      projects: const [],
      disclaimers: overview.disclaimers,
      summary: Summary.of(const []),
      meta: overview.meta,
      truncated: false,
      national: true,
      note: null,
    );
  }

  Future<ScopeResult> _district(DistrictPlace place) async {
    final detail = await _api.district(place.id);
    final card = detail.data.card;
    final jobs = <_Job>[];

    for (final office in detail.data.offices) {
      final name = _officeFilter(office);
      if (name == null || name.isEmpty) continue;
      jobs.add(
        _Job(
          kind: 'office',
          label: name,
          dataset: 'dpwh',
          filters: {'office': name},
        ),
      );
    }

    final q = card.jurisdiction.isNotEmpty
        ? card.jurisdiction
        : place.jurisdiction;
    for (final dataset in AppConfig.datasets) {
      jobs.add(
        _Job(kind: 'place', label: q, dataset: dataset, filters: {'q': q}),
      );
    }

    final result = await _fromJobs(jobs);
    return ScopeResult(
      projects: result.projects,
      disclaimers: result.disclaimers,
      summary: result.summary,
      meta: result.meta ?? detail.meta,
      truncated: result.truncated,
      national: false,
      note: detail.data.sharedOfficeTotal
          ? 'A shared office total is shown whole. Its money is never split between the districts it serves.'
          : null,
    );
  }

  String? _officeFilter(DistrictOffice office) {
    final path = office.projectsApi;
    if (path == null) return null;
    final uri = Uri.tryParse(path);
    return uri?.queryParameters['office'];
  }

  Future<ScopeResult> _fromJobs(List<_Job> jobs) async {
    final pages = await Future.wait(
      jobs.map((job) => _api.projects(job.dataset, job.filters)),
    );

    final byKey = <String, ScopedProject>{};
    final disclaimers = <String, Disclaimer>{};
    BudgetMeta? meta;
    var truncated = false;

    for (var i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final page = pages[i];
      meta ??= page.meta;
      truncated = truncated || page.data.truncated;
      for (final disclaimer in page.disclaimers) {
        disclaimers.putIfAbsent(disclaimer.id, () => disclaimer);
      }

      for (final row in page.data.rows) {
        final reason = Reason(job.kind, job.label);
        final existing = byKey[row.key];
        if (existing == null) {
          byKey[row.key] = ScopedProject(project: row, reasons: [reason]);
        } else if (!existing.reasons.any(
          (item) => item.kind == reason.kind && item.label == reason.label,
        )) {
          existing.reasons.add(reason);
        }
      }
    }

    final projects = byKey.values.toList()..sort(_compare);
    final orderedDisclaimers = disclaimers.values.toList()
      ..sort((a, b) {
        final aLast = a.id == 'disclaimer-offices' ? 1 : 0;
        final bLast = b.id == 'disclaimer-offices' ? 1 : 0;
        return aLast.compareTo(bLast);
      });

    return ScopeResult(
      projects: projects,
      disclaimers: orderedDisclaimers,
      summary: Summary.of(projects.map((item) => item.project)),
      meta: meta,
      truncated: truncated,
      national: false,
      note: null,
    );
  }

  int _compare(ScopedProject a, ScopedProject b) {
    final byHouse = _desc(a.project.housePhp, b.project.housePhp);
    if (byHouse != 0) return byHouse;
    final byNep = _desc(a.project.nepPhp, b.project.nepPhp);
    if (byNep != 0) return byNep;
    return a.project.title.toLowerCase().compareTo(
      b.project.title.toLowerCase(),
    );
  }

  int _desc(int? a, int? b) => (b ?? -1).compareTo(a ?? -1);
}
