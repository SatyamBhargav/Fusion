import 'package:dio/dio.dart';

import '../network_exception.dart';

/// Attaches a [NetworkException] to every failed request, so callers never
/// need to know dio's error types.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: NetworkException.fromDio(err)));
  }
}
