import '../../core/config/app_config.dart';
import '../models/budget_models.dart';
import '../models/place.dart';
import 'budget_api.dart';

class GaaRow {
  const GaaRow({required this.program, required this.department});

  final GaaProgram program;
  final String department;
}

class GaaDataset {
  const GaaDataset({
    required this.rows,
    required this.totals,
    required this.q,
    required this.departmentsSearched,
    required this.matchedFamilies,
    required this.truncated,
    required this.national,
    required this.scopeLabel,
    required this.regionFallback,
  });

  final List<GaaRow> rows;
  final Map<int, int> totals;
  final String q;
  final int departmentsSearched;
  final int matchedFamilies;
  final bool truncated;
  final bool national;
  final String scopeLabel;
  final bool regionFallback;

  int totalFor(int year) => totals[year] ?? 0;

  List<GaaRow> fundedIn(int year, {String query = ''}) {
    final needle = query.trim().toLowerCase();
    final funded = rows
        .where((row) => row.program.fundedIn(year))
        .where(
          (row) =>
              needle.isEmpty ||
              row.program.name.toLowerCase().contains(needle) ||
              row.department.toLowerCase().contains(needle),
        )
        .toList();
    funded.sort(
      (a, b) => _desc(a.program.amountFor(year), b.program.amountFor(year)),
    );
    return funded;
  }

  int _desc(int a, int b) => b.compareTo(a);
}

class GaaService {
  GaaService(this._api);

  final BudgetApi _api;

  Future<GaaDataset> load(PlaceSelection place) async {
    switch (place) {
      case NationalPlace():
        return _national('All Philippines');
      case RegionPlace():
        return _national('All Philippines', regionFallback: true);
      case DistrictPlace():
        final q = place.jurisdiction.isNotEmpty
            ? place.jurisdiction
            : place.label;
        return _search(q);
      case NamedPlace():
        return _search(place.q);
    }
  }

  Future<GaaDataset> _national(
    String label, {
    bool regionFallback = false,
  }) async {
    final national = await _api.nationalGaa();
    final rows = national.departments.map((department) {
      final years = department.years;
      final latest = years[AppConfig.gaaYears.last];
      return GaaRow(
        program: GaaProgram(
          departmentId: department.id,
          agencyId: department.id,
          famKey: department.id,
          name: department.description,
          idsCount: latest?.count ?? 0,
          years: years,
        ),
        department: '',
      );
    }).toList();

    rows.sort(
      (a, b) => b.program
          .amountFor(AppConfig.gaaYears.last)
          .compareTo(a.program.amountFor(AppConfig.gaaYears.last)),
    );

    return GaaDataset(
      rows: rows,
      totals: national.totals,
      q: '',
      departmentsSearched: national.departments.length,
      matchedFamilies: rows.length,
      truncated: false,
      national: true,
      scopeLabel: label,
      regionFallback: regionFallback,
    );
  }

  Future<GaaDataset> _search(String q) async {
    final departments = await _api.gaaDepartments();
    final rows = <GaaRow>[];
    final seen = <String>{};
    var matched = 0;
    var truncated = false;

    Future<void> loadDepartment(GaaDepartment department) async {
      final page = await _api.gaaPrograms(department.id, q);
      matched += page.matched;
      truncated = truncated || page.truncated;
      for (final program in page.rows) {
        final key = '${department.id}:${program.famKey}';
        if (seen.add(key)) {
          rows.add(
            GaaRow(program: program, department: department.description),
          );
        }
      }
    }

    for (var i = 0; i < departments.length; i += 4) {
      await Future.wait(departments.skip(i).take(4).map(loadDepartment));
    }

    final totals = <int, int>{for (final year in AppConfig.gaaYears) year: 0};
    for (final row in rows) {
      for (final year in AppConfig.gaaYears) {
        final amount = row.program.amountFor(year);
        if (amount > 0) totals[year] = (totals[year] ?? 0) + amount;
      }
    }

    final latest = AppConfig.gaaYears.last;
    rows.sort((a, b) {
      final byLatest = b.program
          .amountFor(latest)
          .compareTo(a.program.amountFor(latest));
      if (byLatest != 0) return byLatest;
      return a.program.name.toLowerCase().compareTo(
        b.program.name.toLowerCase(),
      );
    });

    return GaaDataset(
      rows: rows,
      totals: totals,
      q: q,
      departmentsSearched: departments.length,
      matchedFamilies: matched,
      truncated: truncated,
      national: false,
      scopeLabel: q,
      regionFallback: false,
    );
  }
}
