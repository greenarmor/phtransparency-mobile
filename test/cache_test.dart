import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bettergov_budget/core/network/api_client.dart';
import 'package:bettergov_budget/core/network/cache_store.dart';
import 'package:bettergov_budget/core/theme/app_theme.dart';
import 'package:bettergov_budget/data/models/budget_models.dart';
import 'package:bettergov_budget/presentation/screens/national_screen.dart';
import 'package:bettergov_budget/providers/budget_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

typedef _Handler = Future<Object?> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  _Handler handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = await handler(options);
    if (result is ResponseBody) return result;
    throw result as Object;
  }
}

ResponseBody _json(Object body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

DioException _connectionError(RequestOptions options) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
    error: 'offline',
  );
}

DioException _serverError(RequestOptions options, int status) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'error': 'query_failed', 'message': 'Unexpected database error'},
    ),
  );
}

ApiClient _client(_Handler handler, {CacheStore? store}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://budget.bettergov.ph'))
    ..httpClientAdapter = _FakeAdapter(handler);
  return ApiClient(dio: dio, cacheStore: store ?? MemoryCacheStore());
}

void main() {
  test('a successful response is returned fresh and written to the cache', () async {
    final store = MemoryCacheStore();
    var calls = 0;
    final client = _client((options) async {
      calls++;
      return _json({'data': {'ok': true}}, 200);
    }, store: store);

    final json = await client.getJson('/api/v1/gaa');

    expect(json['data'], {'ok': true});
    expect(calls, 1);
    expect(client.servingFromCache.value, isFalse);

    final saved = await store.read(
      'https://budget.bettergov.ph/api/v1/gaa',
    );
    expect(saved, isNotNull);
    final envelope = jsonDecode(saved!) as Map<String, dynamic>;
    expect(envelope['url'], 'https://budget.bettergov.ph/api/v1/gaa');
    expect(envelope['saved_at'], isNotNull);
    expect(envelope['body']['data'], {'ok': true});
  });

  test('a connection failure falls back to the cached response', () async {
    var primed = false;
    final client = _client((options) async {
      if (!primed) {
        primed = true;
        return _json({'data': {'version': 1}}, 200);
      }
      throw _connectionError(options);
    });

    await client.getJson('/api/v1/gaa');

    final cached = await client.getJson('/api/v1/gaa');

    expect(cached['data'], {'version': 1});
    expect(client.servingFromCache.value, isTrue);
  });

  test('recovery clears the cache flag and stores the newer body', () async {
    var version = 1;
    final store = MemoryCacheStore();
    final client = _client((options) async {
      return _json({'data': {'version': version}}, 200);
    }, store: store);

    await client.getJson('/api/v1/gaa');

    final offline = _client((options) async {
      throw _connectionError(options);
    }, store: store);
    await offline.getJson('/api/v1/gaa');
    expect(offline.servingFromCache.value, isTrue);

    version = 2;
    final recovered = _client((options) async {
      return _json({'data': {'version': version}}, 200);
    }, store: store);
    final fresh = await recovered.getJson('/api/v1/gaa');

    expect(fresh['data'], {'version': 2});
    expect(recovered.servingFromCache.value, isFalse);

    final cachedAgain = await offline.getJson('/api/v1/gaa');
    expect(cachedAgain['data'], {'version': 2});
  });

  test('a 5xx falls back to the cache because the server is down', () async {
    var primed = false;
    final client = _client((options) async {
      if (!primed) {
        primed = true;
        return _json({'data': {'ok': true}}, 200);
      }
      throw _serverError(options, 503);
    });

    await client.getJson('/api/v1/gaa');
    final cached = await client.getJson('/api/v1/gaa');

    expect(cached['data'], {'ok': true});
    expect(client.servingFromCache.value, isTrue);
  });

  test('a 404 never serves cache, even when one exists', () async {
    var primed = false;
    final client = _client((options) async {
      if (!primed) {
        primed = true;
        return _json({'data': {'ok': true}}, 200);
      }
      final notFound = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'error': 'not_found', 'message': 'No GAA department 99'},
        ),
      );
      throw notFound;
    });

    await client.getJson('/api/v1/gaa');

    await expectLater(
      client.getJson('/api/v1/gaa/departments/99'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'No GAA department 99',
        ),
      ),
    );
    expect(client.servingFromCache.value, isFalse);
  });

  test('offline with no cache raises the connection error as before', () async {
    final client = _client((options) async {
      throw _connectionError(options);
    });

    await expectLater(
      client.getJson('/api/v1/gaa'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'No connection to the budget API. Check your network.',
        ),
      ),
    );
  });

  test('query parameters are part of the cache key', () async {
    final store = MemoryCacheStore();
    final client = _client((options) async {
      return _json({'data': {'q': options.uri.queryParameters['q']}}, 200);
    }, store: store);

    await client.getJson('/api/v1/gaa', query: {'q': 'bohol'});
    await client.getJson('/api/v1/gaa', query: {'q': 'cebu'});

    expect(await store.read(
      'https://budget.bettergov.ph/api/v1/gaa?q=bohol',
    ), isNotNull);
    expect(await store.read(
      'https://budget.bettergov.ph/api/v1/gaa?q=cebu',
    ), isNotNull);
  });

  test('the file store persists across instances and survives torn files', () async {
    final dir = await Directory.systemTemp.createTemp('bg-cache-test');
    addTearDown(() => dir.delete(recursive: true));

    const key = 'https://budget.bettergov.ph/api/v1/gaa';
    final envelope = jsonEncode({
      'url': key,
      'saved_at': '2026-11-10T00:00:00',
      'body': {'data': [1, 2, 3]},
    });

    await FileCacheStore(directory: dir).write(key, envelope);

    final reopened = FileCacheStore(directory: dir);
    expect(await reopened.read(key), envelope);

    final files = await Directory(
      '${dir.path}${Platform.pathSeparator}api-cache',
    ).list().toList();
    expect(files, hasLength(1));

    await (files.single as File).writeAsString('{ torn json');
    final offline = _client((options) async {
      throw _connectionError(options);
    }, store: FileCacheStore(directory: dir));
    await expectLater(
      offline.getJson(key),
      throwsA(isA<ApiException>()),
    );
    expect(offline.servingFromCache.value, isFalse);
  });

  testWidgets('the app bar shows the saved-data icon when offline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final notifier = ValueNotifier<bool>(true);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const NationalScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          overviewProvider.overrideWith((ref) async => const Overview(
                title: '',
                summary: '',
                rules: [],
                disclaimers: [],
                meta: BudgetMeta(dataset: 'hgab', notice: ''),
                datasets: [],
              )),
          regionsProvider.overrideWith(
            (ref) async => const RegionsPage(
              regions: [],
              notOnMapNep: null,
              notOnMapHouse: null,
              note: '',
            ),
          ),
          servingFromCacheProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Saved data · the API is unreachable'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

    notifier.value = false;
    await tester.pump();

    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
  });
}
