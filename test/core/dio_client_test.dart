import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion/core/error/failures.dart';
import 'package:fusion/core/network/dio_client.dart';
import 'package:fusion/core/network/network_exception.dart';

/// Answers every request with [status], or fails the connection.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.status = 200, this.connectionError = false});

  final int status;
  final bool connectionError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (connectionError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioClient _client(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  return DioClient(dio: dio);
}

void main() {
  test('returns successful responses', () async {
    final res = await _client(_Adapter()).get<Map<String, dynamic>>('/x');
    expect(res.data, {'ok': true});
  });

  test('a server error becomes a NetworkException with its status', () async {
    final call = _client(_Adapter(status: 503)).get<Object?>('/x');
    await expectLater(
      call,
      throwsA(
        isA<NetworkException>()
            .having((e) => e.kind, 'kind', NetworkErrorKind.badResponse)
            .having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
  });

  test('no connection maps to a NetworkFailure for the UI', () async {
    try {
      await _client(_Adapter(connectionError: true)).post<Object?>('/x');
      fail('should throw');
    } on NetworkException catch (e) {
      expect(e.kind, NetworkErrorKind.noConnection);
      expect(e.toFailure(), isA<NetworkFailure>());
    }
  });
}
