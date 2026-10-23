import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'interceptors/error_interceptor.dart';
import 'network_exception.dart';

/// The app's HTTP client. Every call either returns a response or throws a
/// [NetworkException].
class DioClient {
  DioClient({Dio? dio, String baseUrl = ApiConfig.baseUrl})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
            ),
          ) {
    this.dio.interceptors.add(ErrorInterceptor());
    if (kDebugMode) {
      // A password manager must never log credentials: URLs and status
      // codes only, no headers or bodies.
      this.dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
  }

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _guard(
    () => dio.get<T>(path, queryParameters: query, cancelToken: cancelToken),
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _guard(
    () => dio.post<T>(
      path,
      data: data,
      queryParameters: query,
      cancelToken: cancelToken,
    ),
  );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) => _guard(() => dio.put<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> delete<T>(String path, {CancelToken? cancelToken}) =>
      _guard(() => dio.delete<T>(path, cancelToken: cancelToken));

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final error = e.error;
      throw error is NetworkException ? error : NetworkException.fromDio(e);
    }
  }
}
