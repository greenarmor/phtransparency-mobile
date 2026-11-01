import 'package:bettergov_budget/core/network/api_client.dart';
import 'package:bettergov_budget/data/services/budget_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Dio _fakeDio(Map<String, dynamic> data, {List<RequestOptions>? seen}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        seen?.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: data,
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  test(
    'projectMatchCount asks for one row and reads the whole total',
    () async {
      final seen = <RequestOptions>[];
      final api = BudgetApi(
        ApiClient(
          dio: _fakeDio({
            'meta': {'dataset': 'hgab'},
            'data': {
              'total': 42,
              'rows': [
                {'id': 'house-reading:1'},
              ],
            },
          }, seen: seen),
        ),
      );

      expect(await api.projectMatchCount('dpwh', 'Carmen'), 42);
      expect(seen.single.path, '/api/v1/hgab/2027/datasets/dpwh/projects');
      expect(seen.single.queryParameters['q'], 'Carmen');
      expect(seen.single.queryParameters['limit'], 1);
    },
  );

  test('projectMatchCount is zero when no total is published', () async {
    final api = BudgetApi(ApiClient(dio: _fakeDio({'meta': {}, 'data': {}})));
    expect(await api.projectMatchCount('fmr', 'Carmen'), 0);
  });
}
