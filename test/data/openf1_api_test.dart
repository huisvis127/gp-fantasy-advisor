import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/sources/openf1_api.dart';

class _RateLimitedAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'rate limited'}),
        429,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode([
        {
          'session_key': 42,
          'session_name': 'Practice 1',
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('reintenta un 429 y cachea la lista de sesiones durante el refresco',
      () async {
    final adapter = _RateLimitedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = OpenF1Api(
      dio,
      baseUrl: 'https://example.test/v1',
      minimumRequestGap: Duration.zero,
      retryBaseDelay: Duration.zero,
    );

    final first = await api.getSessions(year: 2026, countryName: 'Spain');
    final second = await api.getSessions(year: 2026, countryName: 'Spain');

    expect(first.single['session_key'], 42);
    expect(second, first);
    expect(adapter.requests, 2);
  });
}
