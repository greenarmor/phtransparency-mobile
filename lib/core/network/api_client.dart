import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.url});

  final String message;
  final int? statusCode;
  final String? url;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = AppConfig.apiBase, Dio? dio})
    : _dio =
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

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      throw ApiException(
        'The budget API returned an unexpected response.',
        statusCode: response.statusCode,
        url: response.requestOptions.uri.toString(),
      );
    } on DioException catch (error) {
      throw ApiException(
        _messageFor(error),
        statusCode: error.response?.statusCode,
        url: error.requestOptions.uri.toString(),
      );
    }
  }

  String _messageFor(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final apiError = body['error'];
      if (apiError is Map && apiError['message'] is String) {
        return apiError['message'] as String;
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
