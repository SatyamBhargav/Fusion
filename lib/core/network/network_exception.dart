import 'package:dio/dio.dart';

import '../error/failures.dart';

enum NetworkErrorKind { timeout, noConnection, cancelled, badResponse, unknown }

/// A failed request, independent of dio. Repositories turn it into a
/// [NetworkFailure] with [toFailure].
class NetworkException implements Exception {
  const NetworkException(this.kind, this.message, {this.statusCode});

  factory NetworkException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkException(
        NetworkErrorKind.timeout,
        'The server took too long to answer.',
      ),
      DioExceptionType.connectionError => const NetworkException(
        NetworkErrorKind.noConnection,
        'No internet connection.',
      ),
      DioExceptionType.cancel => const NetworkException(
        NetworkErrorKind.cancelled,
        'The request was cancelled.',
      ),
      DioExceptionType.badResponse => NetworkException(
        NetworkErrorKind.badResponse,
        status != null && status >= 500
            ? 'The server had a problem. Try again later.'
            : 'The request was refused.',
        statusCode: status,
      ),
      _ => const NetworkException(
        NetworkErrorKind.unknown,
        'Something went wrong. Try again.',
      ),
    };
  }

  final NetworkErrorKind kind;
  final String message;
  final int? statusCode;

  NetworkFailure toFailure() => NetworkFailure(message, statusCode: statusCode);

  @override
  String toString() => 'NetworkException($kind, $statusCode): $message';
}
