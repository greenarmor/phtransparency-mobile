import 'dart:math' as math;

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

class GaaPage {
  const GaaPage({
    required this.rows,
    required this.matched,
    required this.truncated,
  });

  final List<GaaProgram> rows;
  final int matched;
  final bool truncated;
}

class BudgetApi {
  BudgetApi(this._client);

  final ApiClient _client;

  static const _root = '/api/v1/hgab/2027';
  static const pageSize = 200;
  static const maxRows = 4000;
  static const gaaPageSize = 500;
  static const maxGaaPrograms = 6000;

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

  Future<int> projectMatchCount(String dataset, String q) async {
    final json = await _client.getJson(
      '$_root/datasets/$dataset/projects',
      query: {'q': q, 'limit': 1},
    );
    final data = json['data'];
    return data is Map ? asInt(data['total']) ?? 0 : 0;
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

  Future<List<GaaDepartment>> gaaDepartments() async {
    final json = await _client.getJson('/api/v1/gaa/departments');
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => GaaDepartment.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<GaaPage> gaaPrograms(String departmentId, String q) async {
    final path = '/api/v1/gaa/departments/$departmentId/programs';
    final firstJson = await _client.getJson(
      path,
      query: {'q': q, 'limit': gaaPageSize},
    );
    final rows = <GaaProgram>[];
    final first = firstJson['data'];
    if (first is List) {
      rows.addAll(
        first.whereType<Map>().map(
          (item) => GaaProgram.fromJson(item.cast<String, dynamic>()),
        ),
      );
    }

    var cursor = firstJson['next_cursor'] as String?;
    var truncated = false;
    while (cursor != null && cursor.isNotEmpty) {
      if (rows.length >= maxGaaPrograms) {
        truncated = true;
        break;
      }
      final page = await _client.getJson(
        path,
        query: {'q': q, 'limit': gaaPageSize, 'cursor': cursor},
      );
      final data = page['data'];
      if (data is List) {
        rows.addAll(
          data.whereType<Map>().map(
            (item) => GaaProgram.fromJson(item.cast<String, dynamic>()),
          ),
        );
      }
      cursor = page['next_cursor'] as String?;
    }

    final meta = firstJson['meta'];
    final matched = meta is Map
        ? asInt(meta['matched']) ?? rows.length
        : rows.length;
    return GaaPage(rows: rows, matched: matched, truncated: truncated);
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
