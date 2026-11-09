import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'cache_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.url});

  final String message;
  final int? statusCode;
  final String? url;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String baseUrl = AppConfig.apiBase,
    Dio? dio,
    this.cacheStore,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 90),
               headers: const {'accept': 'application/json'},
             ),
           );

  final Dio _dio;
  final CacheStore? cacheStore;

  /// True while responses are being served from the local cache because the
  /// remote API cannot be reached. Resets on the next successful network call.
  final ValueNotifier<bool> servingFromCache = ValueNotifier(false);

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      final data = response.data;
      final Map<String, dynamic> parsed;
      if (data is Map<String, dynamic>) {
        parsed = data;
      } else if (data is Map) {
        parsed = data.cast<String, dynamic>();
      } else {
        throw ApiException(
          'The budget API returned an unexpected response.',
          statusCode: response.statusCode,
          url: response.requestOptions.uri.toString(),
        );
      }
      servingFromCache.value = false;
      await _writeCache(response.requestOptions.uri.toString(), parsed);
      return parsed;
    } on DioException catch (error) {
      final url = error.requestOptions.uri.toString();
      if (_isRemoteUnavailable(error)) {
        final cached = await _readCache(url);
        if (cached != null) {
          servingFromCache.value = true;
          return cached;
        }
      }
      throw ApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
        url: url,
      );
    }
  }

  /// Network-level failures and 5xx mean the server is down; everything else
  /// (400, 404, bad cursor) is a real answer and must not be masked by cache.
  bool _isRemoteUnavailable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return (error.response?.statusCode ?? 0) >= 500;
      default:
        return false;
    }
  }

  Future<void> _writeCache(String url, Map<String, dynamic> body) async {
    final store = cacheStore;
    if (store == null) return;
    try {
      await store.write(
        url,
        jsonEncode({
          'url': url,
          'saved_at': DateTime.now().toIso8601String(),
          'body': body,
        }),
      );
    } catch (_) {
      // A failed cache write must never break a working network response.
    }
  }

  Future<Map<String, dynamic>?> _readCache(String url) async {
    final store = cacheStore;
    if (store == null) return null;
    try {
      final raw = await store.read(url);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['url'] != url) return null;
      final body = decoded['body'];
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return body.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }

  String _messageFor(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final apiError = body['error'];
      final message = body['message'];
      if (apiError is Map && apiError['message'] is String) {
        return apiError['message'] as String;
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The budget API took too long to answer.';
      case DioExceptionType.connectionError:
        return 'No connection to the budget API. Check your network.';
      default:
        final status = error.response?.statusCode;
        return status == null
            ? 'The budget API could not be reached.'
            : 'The budget API answered $status.';
    }
  }
}
