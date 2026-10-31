int? asInt(Object? value) => value is num ? value.toInt() : null;

double? asDouble(Object? value) => value is num ? value.toDouble() : null;

String? asString(Object? value) => value is String ? value : null;

List<String> asStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

Map<String, String> asStringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}

class Disclaimer {
  const Disclaimer({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;

  factory Disclaimer.fromJson(Map<String, dynamic> json) => Disclaimer(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}

class BudgetMeta {
  const BudgetMeta({
    required this.dataset,
    required this.notice,
    this.fiscalYear,
    this.sourceRepo,
    this.sourceCommit,
    this.builtAt,
  });

  final String dataset;
  final String notice;
  final int? fiscalYear;
  final String? sourceRepo;
  final String? sourceCommit;
  final String? builtAt;

  factory BudgetMeta.fromJson(Map<String, dynamic> json) => BudgetMeta(
    dataset: json['dataset'] as String? ?? '',
    notice: json['notice'] as String? ?? '',
    fiscalYear: asInt(json['fiscal_year']),
    sourceRepo: asString(json['source_repo']),
    sourceCommit: asString(json['source_commit']),
    builtAt: asString(json['built_at']),
  );
}

class ProjectRow {
  const ProjectRow({
    required this.id,
    required this.dataset,
    required this.title,
    required this.program,
    required this.pap,
    required this.office,
    required this.region,
    required this.regionKey,
    required this.statusLabel,
    required this.bridgeGroup,
    required this.groupLabel,
    required this.held,
    required this.nepPhp,
    required this.hgab2Php,
    required this.hgab3Php,
    required this.housePhp,
    required this.apiPhp,
    required this.deltaPhp,
    required this.nepPage,
    required this.hgab2Page,
    required this.hgab3Page,
    required this.pdfUrl,
    required this.flags,
    required this.url,
  });

  final String id;
  final String dataset;
  final String title;
  final String? program;
  final String? pap;
  final String? office;
  final String? region;
  final String? regionKey;
  final String statusLabel;
  final String bridgeGroup;
  final String groupLabel;
  final bool held;
  final int? nepPhp;
  final int? hgab2Php;
  final int? hgab3Php;
  final int? housePhp;
  final int? apiPhp;
  final int? deltaPhp;
  final int? nepPage;
  final int? hgab2Page;
  final int? hgab3Page;
  final Map<String, String> pdfUrl;
  final List<String> flags;
  final String url;

  String get key => '$dataset:$id';

  factory ProjectRow.fromJson(Map<String, dynamic> json) => ProjectRow(
    id: json['id'] as String? ?? '',
    dataset: json['dataset'] as String? ?? '',
    title: json['title'] as String? ?? '',
    program: asString(json['program']),
    pap: asString(json['pap']),
    office: asString(json['office']),
    region: asString(json['region']),
    regionKey: asString(json['region_key']),
    statusLabel: json['status_label'] as String? ?? '',
    bridgeGroup: json['bridge_group'] as String? ?? 'unchanged',
    groupLabel: json['group_label'] as String? ?? '',
    held: json['held'] as bool? ?? false,
    nepPhp: asInt(json['nep_php']),
    hgab2Php: asInt(json['hgab2_php']),
    hgab3Php: asInt(json['hgab3_php']),
    housePhp: asInt(json['house_php']),
    apiPhp: asInt(json['api_php']),
    deltaPhp: asInt(json['delta_php']),
    nepPage: asInt(json['nep_page']),
    hgab2Page: asInt(json['hgab2_page']),
    hgab3Page: asInt(json['hgab3_page']),
    pdfUrl: asStringMap(json['pdf_url']),
    flags: asStringList(json['flags']),
    url: json['url'] as String? ?? '',
  );
}

class ProjectSums {
  const ProjectSums({
    required this.nepPhp,
    required this.hgab2Php,
    required this.hgab3Php,
    required this.unconfirmedRows,
  });

  final int? nepPhp;
  final int? hgab2Php;
  final int? hgab3Php;
  final int unconfirmedRows;

  factory ProjectSums.fromJson(Map<String, dynamic>? json) => ProjectSums(
    nepPhp: asInt(json?['nep_php']),
    hgab2Php: asInt(json?['hgab2_php']),
    hgab3Php: asInt(json?['hgab3_php']),
    unconfirmedRows: asInt(json?['unconfirmed_rows']) ?? 0,
  );
}

class ProjectPage {
  const ProjectPage({
    required this.total,
    required this.rows,
    required this.sums,
    required this.truncated,
  });

  final int total;
  final List<ProjectRow> rows;
  final ProjectSums sums;
  final bool truncated;

  factory ProjectPage.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    return ProjectPage(
      total: asInt(json['total']) ?? 0,
      rows: rows is List
          ? rows
                .whereType<Map>()
                .map((row) => ProjectRow.fromJson(row.cast<String, dynamic>()))
                .toList()
          : const [],
      sums: ProjectSums.fromJson(
        json['sums'] is Map
            ? (json['sums'] as Map).cast<String, dynamic>()
            : null,
      ),
      truncated: false,
    );
  }
}

class DetailLabel {
  const DetailLabel({required this.code, required this.label, this.help});

  final String code;
  final String label;
  final String? help;

  factory DetailLabel.fromJson(Map<String, dynamic> json) => DetailLabel(
    code: json['code'] as String? ?? '',
    label: json['label'] as String? ?? '',
    help: asString(json['help']),
  );
}

class ProjectDetail {
  const ProjectDetail({
    required this.row,
    required this.houseMatch,
    required this.readingStatus,
    required this.apiPresence,
    required this.confidence,
    required this.lengthM,
    required this.statusLabel,
    required this.matchLabel,
    required this.readingLabel,
    required this.dpwhSiteLabel,
    required this.zoneLabel,
    required this.flagLabels,
  });

  final ProjectRow row;
  final String? houseMatch;
  final String? readingStatus;
  final String? apiPresence;
  final double? confidence;
  final int? lengthM;
  final String? statusLabel;
  final String? matchLabel;
  final String? readingLabel;
  final String? dpwhSiteLabel;
  final String? zoneLabel;
  final List<String> flagLabels;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final labels = json['labels'] is Map
        ? (json['labels'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    DetailLabel? label(Object? value) {
      if (value is! Map) return null;
      return DetailLabel.fromJson(value.cast<String, dynamic>());
    }

    final flags = labels['flags'];
    return ProjectDetail(
      row: ProjectRow.fromJson(json),
      houseMatch: asString(json['house_match']),
      readingStatus: asString(json['reading_status']),
      apiPresence: asString(json['api_presence']),
      confidence: asDouble(json['confidence']),
      lengthM: asInt(json['length_m']),
      statusLabel: label(labels['status'])?.label,
      matchLabel: label(labels['match'])?.label,
      readingLabel: label(labels['reading'])?.label,
      dpwhSiteLabel: label(labels['dpwh_site'])?.label,
      zoneLabel: label(labels['zone'])?.label,
      flagLabels: flags is List
          ? flags
                .whereType<Map>()
                .map(
                  (f) => DetailLabel.fromJson(f.cast<String, dynamic>()).label,
                )
                .where((text) => text.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class Overview {
  const Overview({
    required this.title,
    required this.summary,
    required this.rules,
    required this.disclaimers,
    required this.meta,
    required this.datasets,
  });

  final String title;
  final String summary;
  final List<String> rules;
  final List<Disclaimer> disclaimers;
  final BudgetMeta meta;
  final List<DatasetTotals> datasets;
}

class GaaYearAmount {
  const GaaYearAmount({required this.count, required this.amount});

  final int count;
  final int amount;

  factory GaaYearAmount.fromJson(Map<String, dynamic> json) => GaaYearAmount(
    count: asInt(json['count']) ?? 0,
    amount: asInt(json['amount']) ?? 0,
  );
}

class GaaDepartment {
  const GaaDepartment({
    required this.id,
    required this.description,
    required this.years,
  });

  final String id;
  final String description;
  final Map<int, GaaYearAmount> years;

  int amountFor(int year) => years[year]?.amount ?? 0;

  factory GaaDepartment.fromJson(Map<String, dynamic> json) {
    final raw = json['years'];
    final years = <int, GaaYearAmount>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final year = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (year != null && value is Map) {
          years[year] = GaaYearAmount.fromJson(value.cast<String, dynamic>());
        }
      }
    }
    return GaaDepartment(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      years: years,
    );
  }
}

class GaaProgram {
  const GaaProgram({
    required this.departmentId,
    required this.agencyId,
    required this.famKey,
    required this.name,
    required this.idsCount,
    required this.years,
  });

  final String departmentId;
  final String agencyId;
  final String famKey;
  final String name;
  final int idsCount;
  final Map<int, GaaYearAmount> years;

  int amountFor(int year) => years[year]?.amount ?? 0;

  bool fundedIn(int year) => amountFor(year) > 0;

  factory GaaProgram.fromJson(Map<String, dynamic> json) {
    final rawYears = json['years'];
    final years = <int, GaaYearAmount>{};
    if (rawYears is Map) {
      for (final entry in rawYears.entries) {
        final year = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (year != null && value is Map) {
          years[year] = GaaYearAmount.fromJson(value.cast<String, dynamic>());
        }
      }
    }
    return GaaProgram(
      departmentId: json['department_id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      famKey: json['fam_key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      idsCount: asInt(json['ids_count']) ?? 0,
      years: years,
    );
  }
}

class DatasetTotals {
  const DatasetTotals({
    required this.key,
    required this.label,
    required this.short,
    required this.nepPhp,
    required this.housePhp,
    required this.nepRows,
    required this.houseRows,
    required this.groups,
  });

  final String key;
  final String label;
  final String short;
  final int? nepPhp;
  final int? housePhp;
  final int? nepRows;
  final int? houseRows;
  final Map<String, GroupTotal> groups;

  factory DatasetTotals.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] is Map
        ? (json['totals'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final counts = json['counts'] is Map
        ? (json['counts'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final bridge = json['bridge'] is Map
        ? (json['bridge'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final rawGroups = bridge['groups'] is Map
        ? (bridge['groups'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return DatasetTotals(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      short: json['short'] as String? ?? '',
      nepPhp: asInt(totals['nep_php']),
      housePhp: asInt(totals['hgab3_php']) ?? asInt(totals['hgab2_php']),
      nepRows: asInt(counts['nep']),
      houseRows: asInt(counts['hgab3']),
      groups: {
        for (final entry in rawGroups.entries)
          if (entry.value is Map)
            entry.key: GroupTotal.fromJson(
              (entry.value as Map).cast<String, dynamic>(),
            ),
      },
    );
  }
}

class GroupTotal {
  const GroupTotal({
    required this.rows,
    required this.php,
    required this.unconfirmedRows,
  });

  final int rows;
  final int php;
  final int unconfirmedRows;

  factory GroupTotal.fromJson(Map<String, dynamic> json) => GroupTotal(
    rows: asInt(json['rows']) ?? 0,
    php: asInt(json['php']) ?? 0,
    unconfirmedRows: asInt(json['unconfirmed_rows']) ?? 0,
  );
}

class OfficeRef {
  const OfficeRef({
    required this.id,
    required this.name,
    required this.tier,
    required this.tierText,
    this.projectsApi,
  });

  final String id;
  final String name;
  final String tier;
  final String tierText;
  final String? projectsApi;

  factory OfficeRef.fromJson(Map<String, dynamic> json) => OfficeRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    tier: json['tier'] as String? ?? '',
    tierText: json['tier_text'] as String? ?? '',
    projectsApi: asString(json['projects_api']),
  );
}

class DistrictSummary {
  const DistrictSummary({
    required this.id,
    required this.label,
    required this.jurisdiction,
    required this.districtLabel,
    required this.region,
    required this.regionKey,
    required this.attributionCode,
    required this.attributionLabel,
    required this.representativeName,
    required this.offices,
    required this.gaa2026,
    required this.nep2027,
    required this.house2027,
    required this.delta2027,
    required this.sharedOfficeTotal,
  });

  final String id;
  final String label;
  final String jurisdiction;
  final String districtLabel;
  final String? region;
  final String? regionKey;
  final String attributionCode;
  final String attributionLabel;
  final String? representativeName;
  final List<OfficeRef> offices;
  final int? gaa2026;
  final int? nep2027;
  final int? house2027;
  final int? delta2027;
  final bool sharedOfficeTotal;

  factory DistrictSummary.fromJson(Map<String, dynamic> json) {
    final attribution = json['attribution'] is Map
        ? (json['attribution'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final representative = json['representative'] is Map
        ? (json['representative'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final headline = json['headline'] is Map
        ? (json['headline'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final change = json['fy2027_vs_proposal'] is Map
        ? (json['fy2027_vs_proposal'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final offices = json['offices'];
    return DistrictSummary(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      jurisdiction: json['jurisdiction'] as String? ?? '',
      districtLabel: json['district_label'] as String? ?? '',
      region: asString(json['region']),
      regionKey: asString(json['region_key']),
      attributionCode: attribution['code'] as String? ?? 'A',
      attributionLabel: attribution['label'] as String? ?? '',
      representativeName: asString(representative['name']),
      offices: offices is List
          ? offices
                .whereType<Map>()
                .map((item) => OfficeRef.fromJson(item.cast<String, dynamic>()))
                .toList()
          : const [],
      gaa2026: asInt(headline['fy2026_gaa_php']),
      nep2027: asInt(headline['fy2027_nep_php']),
      house2027: asInt(headline['fy2027_hgab3_php']),
      delta2027: asInt(change['delta_php']),
      sharedOfficeTotal: headline['shared_office_total'] as bool? ?? false,
    );
  }
}

class DistrictPage {
  const DistrictPage({required this.total, required this.districts});

  final int total;
  final List<DistrictSummary> districts;

  factory DistrictPage.fromJson(Map<String, dynamic> json) {
    final list = json['districts'];
    return DistrictPage(
      total: asInt(json['total']) ?? 0,
      districts: list is List
          ? list
                .whereType<Map>()
                .map(
                  (item) =>
                      DistrictSummary.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : const [],
    );
  }
}

class OfficeYear {
  const OfficeYear({
    required this.fy,
    required this.stage,
    required this.php,
    required this.matchedLabel,
  });

  final int? fy;
  final String stage;
  final int? php;
  final String? matchedLabel;

  factory OfficeYear.fromJson(Map<String, dynamic> json) => OfficeYear(
    fy: asInt(json['fy']),
    stage: json['stage'] as String? ?? '',
    php: asInt(json['php']),
    matchedLabel: asString(json['matched_label']),
  );
}

class DistrictOffice {
  const DistrictOffice({
    required this.id,
    required this.name,
    required this.tier,
    required this.tierText,
    required this.projectsApi,
    required this.years,
    required this.nep2027,
    required this.house2027,
    required this.nepRows,
    required this.houseRows,
  });

  final String id;
  final String name;
  final String tier;
  final String tierText;
  final String? projectsApi;
  final List<OfficeYear> years;
  final int? nep2027;
  final int? house2027;
  final int? nepRows;
  final int? houseRows;

  factory DistrictOffice.fromJson(Map<String, dynamic> json) {
    final years = json['years'];
    final fy2027 = json['fy2027'] is Map
        ? (json['fy2027'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return DistrictOffice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      tierText: json['tier_text'] as String? ?? '',
      projectsApi: asString(json['projects_api']),
      years: years is List
          ? years
                .whereType<Map>()
                .map(
                  (item) => OfficeYear.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      nep2027: asInt(fy2027['nep_php']),
      house2027: asInt(fy2027['hgab3_php']),
      nepRows: asInt(fy2027['nep_records']),
      houseRows: asInt(fy2027['hgab3_records']),
    );
  }
}

class DistrictDetail {
  const DistrictDetail({
    required this.card,
    required this.offices,
    required this.sharedOfficeTotal,
    required this.coServedLabels,
  });

  final DistrictSummary card;
  final List<DistrictOffice> offices;
  final bool sharedOfficeTotal;
  final List<String> coServedLabels;

  factory DistrictDetail.fromJson(Map<String, dynamic> json) {
    final card = DistrictSummary.fromJson(json);
    final offices = json['offices'];
    final coServed = json['co_served_districts'];
    return DistrictDetail(
      card: card,
      offices: offices is List
          ? offices
                .whereType<Map>()
                .map(
                  (item) =>
                      DistrictOffice.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      sharedOfficeTotal: card.sharedOfficeTotal,
      coServedLabels: coServed is List
          ? coServed
                .whereType<Map>()
                .map((item) => item['label'] as String? ?? '')
                .where((label) => label.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class RegionRow {
  const RegionRow({
    required this.key,
    required this.label,
    required this.name,
    required this.nepPhp,
    required this.housePhp,
    required this.deltaPhp,
    required this.nepRows,
    required this.houseRows,
  });

  final String key;
  final String label;
  final String name;
  final int? nepPhp;
  final int? housePhp;
  final int? deltaPhp;
  final int? nepRows;
  final int? houseRows;

  factory RegionRow.fromJson(Map<String, dynamic> json) => RegionRow(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nepPhp: asInt(json['nep_php']),
    housePhp: asInt(json['house_php']),
    deltaPhp: asInt(json['delta_php']),
    nepRows: asInt(json['nep_rows']),
    houseRows: asInt(json['house_rows']),
  );
}

class RegionsPage {
  const RegionsPage({
    required this.regions,
    required this.notOnMapNep,
    required this.notOnMapHouse,
    required this.note,
  });

  final List<RegionRow> regions;
  final int? notOnMapNep;
  final int? notOnMapHouse;
  final String note;

  factory RegionsPage.fromJson(Map<String, dynamic> json) {
    final regions = json['regions'];
    final notOnMap = json['not_on_map'] is Map
        ? (json['not_on_map'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return RegionsPage(
      regions: regions is List
          ? regions
                .whereType<Map>()
                .map((item) => RegionRow.fromJson(item.cast<String, dynamic>()))
                .toList()
          : const [],
      notOnMapNep: asInt(notOnMap['nep_php']),
      notOnMapHouse: asInt(notOnMap['house_php']),
      note: json['note'] as String? ?? '',
    );
  }
}

class NationalGaa {
  const NationalGaa({required this.totals, required this.departments});

  final Map<int, int> totals;
  final List<GaaDepartment> departments;

  int totalFor(int year) => totals[year] ?? 0;
}
