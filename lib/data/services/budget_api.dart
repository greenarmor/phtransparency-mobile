import 'dart:math' as math;

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/budget_models.dart';

class Envelope<T> {
  const Envelope({
    required this.data,
    required this.meta,
    required this.disclaimers,
  });

  final T data;
  final BudgetMeta meta;
  final List<Disclaimer> disclaimers;
}

class BudgetApi {
  BudgetApi(this._client);

  final ApiClient _client;

  static const _root = '/api/v1/hgab/2027';
  static const pageSize = 200;
  static const maxRows = 4000;
  static const gaaPageSize = 500;

  Future<Envelope<Overview>> overview() async {
    final json = await _client.getJson(_root);
    final data = (json['data'] as Map).cast<String, dynamic>();
    final datasets = data['datasets'];
    return Envelope(
      data: Overview(
        title: data['title'] as String? ?? '',
        summary: data['summary'] as String? ?? '',
        rules: asStringList(data['rules']),
        disclaimers: _disclaimers(json),
        meta: _meta(json),
        datasets: datasets is List
            ? datasets
                  .whereType<Map>()
                  .map(
                    (item) =>
                        DatasetTotals.fromJson(item.cast<String, dynamic>()),
                  )
                  .toList()
            : const [],
      ),
      meta: _meta(json),
      disclaimers: _disclaimers(json),
    );
  }

  Future<Envelope<ProjectPage>> projects(
    String dataset,
    Map<String, dynamic> filters,
  ) async {
    final path = '$_root/datasets/$dataset/projects';
    final firstJson = await _client.getJson(
      path,
      query: {...filters, 'limit': pageSize, 'offset': 0},
    );
    final first = _page(firstJson);
    final total = math.min(first.total, maxRows);
    final rows = <ProjectRow>[...first.rows];

    final offsets = <int>[
      for (var offset = pageSize; offset < total; offset += pageSize) offset,
    ];
    for (var i = 0; i < offsets.length; i += 4) {
      final batch = offsets.skip(i).take(4).toList();
      final pages = await Future.wait(
        batch.map(
          (offset) => _client.getJson(
            path,
            query: {...filters, 'limit': pageSize, 'offset': offset},
          ),
        ),
      );
      for (final page in pages) {
        rows.addAll(_page(page).rows);
      }
    }

    return Envelope(
      data: ProjectPage(
        total: first.total,
        rows: rows,
        sums: first.sums,
        truncated: first.total > maxRows,
      ),
      meta: _meta(firstJson),
      disclaimers: _disclaimers(firstJson),
    );
  }

  Future<Envelope<ProjectDetail>> project(String dataset, String id) async {
    final json = await _client.getJson(
      '$_root/datasets/$dataset/projects/${Uri.encodeComponent(id)}',
    );
    return Envelope(
      data: ProjectDetail.fromJson(
        (json['data'] as Map).cast<String, dynamic>(),
      ),
      meta: _meta(json),
      disclaimers: _disclaimers(json),
    );
  }

  Future<List<ProjectRow>> projectRowsFor(String q, {int limit = 200}) async {
    final json = await _client.getJson(
      '$_root/datasets/dpwh/projects',
      query: {'q': q, 'limit': limit},
    );
    final data = json['data'];
    if (data is! Map) return const [];
    final rows = data['rows'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => ProjectRow.fromJson(row.cast<String, dynamic>()))
        .toList();
  }

  /// Every row in one bridge group for one dataset, paged through in full so
  /// the campaign ledger can be searched and paged in place.
  Future<List<ProjectRow>> groupAllRows(String dataset, String group) async {
    final path = '$_root/datasets/$dataset/projects';
    final firstJson = await _client.getJson(
      path,
      query: {'group': group, 'limit': pageSize, 'offset': 0},
    );
    final first = _page(firstJson);
    final rows = <ProjectRow>[...first.rows];
    final offsets = <int>[
      for (var offset = pageSize; offset < first.total; offset += pageSize)
        offset,
    ];
    for (var i = 0; i < offsets.length; i += 4) {
      final batch = offsets.skip(i).take(4).toList();
      final pages = await Future.wait(
        batch.map(
          (offset) => _client.getJson(
            path,
            query: {'group': group, 'limit': pageSize, 'offset': offset},
          ),
        ),
      );
      for (final page in pages) {
        rows.addAll(_page(page).rows);
      }
    }
    return rows;
  }

  Future<Envelope<DistrictPage>> districts({
    String? q,
    int limit = 30,
    int offset = 0,
    String sort = 'hgab3',
  }) async {
    final json = await _client.getJson(
      '$_root/districts',
      query: {
        'limit': limit,
        'offset': offset,
        'sort': sort,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return Envelope(
      data: DistrictPage.fromJson(
        (json['data'] as Map).cast<String, dynamic>(),
      ),
      meta: _meta(json),
      disclaimers: _disclaimers(json),
    );
  }

  Future<Envelope<DistrictDetail>> district(String id) async {
    final json = await _client.getJson(
      '$_root/districts/${Uri.encodeComponent(id)}',
    );
    return Envelope(
      data: DistrictDetail.fromJson(
        (json['data'] as Map).cast<String, dynamic>(),
      ),
      meta: _meta(json),
      disclaimers: _disclaimers(json),
    );
  }

  Future<Envelope<RegionsPage>> regions([String dataset = 'dpwh']) async {
    final json = await _client.getJson('$_root/datasets/$dataset/regions');
    return Envelope(
      data: RegionsPage.fromJson((json['data'] as Map).cast<String, dynamic>()),
      meta: _meta(json),
      disclaimers: _disclaimers(json),
    );
  }

  Future<NationalGaa> nationalGaa() async {
    final totalsJson = await _client.getJson('/api/v1/gaa');
    final departmentsJson = await _client.getJson('/api/v1/gaa/departments');
    final totals = <int, int>{};
    final rawTotals = totalsJson['data'];
    if (rawTotals is List) {
      for (final item in rawTotals.whereType<Map>()) {
        final year = asInt(item['year']);
        final amount = asInt(item['amount']);
        if (year != null && amount != null) totals[year] = amount;
      }
    }
    final rawDepartments = departmentsJson['data'];
    final departments = rawDepartments is List
        ? rawDepartments
              .whereType<Map>()
              .map(
                (item) => GaaDepartment.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
        : <GaaDepartment>[];
    return NationalGaa(totals: totals, departments: departments);
  }

  Future<GaaSnapshot> gaaYearSnapshot(int year) async {
    final json = await _client.getJson('/api/v1/gaa/years/$year');
    return GaaSnapshot.fromEnvelope(json, year);
  }

  Future<GaaDepartmentDetail> gaaDepartment(String departmentId) async {
    final json = await _client.getJson('/api/v1/gaa/departments/$departmentId');
    return GaaDepartmentDetail.fromEnvelope(json);
  }

  Future<GaaChildrenPage> gaaChildren(
    int year,
    String departmentId, {
    String level = 'agencies',
    String? parent,
  }) async {
    final json = await _client.getJson(
      '/api/v1/gaa/years/$year/departments/$departmentId/children',
      query: {
        'level': level,
        if (parent != null && parent.isNotEmpty) 'parent': parent,
        'limit': gaaPageSize,
      },
    );
    return GaaChildrenPage.fromEnvelope(json);
  }

  Future<GaaRegional> gaaRegional() async {
    final json = await _client.getJson(AppConfig.regionalGaaUrl);
    return GaaRegional.fromEnvelope(json);
  }

  ProjectPage _page(Map<String, dynamic> json) =>
      ProjectPage.fromJson((json['data'] as Map).cast<String, dynamic>());

  BudgetMeta _meta(Map<String, dynamic> json) {
    final meta = json['meta'];
    return meta is Map
        ? BudgetMeta.fromJson(meta.cast<String, dynamic>())
        : const BudgetMeta(dataset: '', notice: '');
  }

  List<Disclaimer> _disclaimers(Map<String, dynamic> json) {
    final list = json['disclaimers'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((item) => Disclaimer.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
