import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/sources/openf1_api.dart';

class _RateLimitedAdapter implements HttpClientAdapter {
  int requests = 0;
  RequestOptions? successfulRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'rate limited'}),
        429,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    successfulRequest = options;
    return ResponseBody.fromString(
      jsonEncode([
        {'session_key': 42, 'session_name': 'Practice 1'},
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

class _EmptyThenDataAdapter implements HttpClientAdapter {
  final requests = <String, int>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.path}:${options.queryParameters['session_key']}';
    final requestCount = (requests[key] ?? 0) + 1;
    requests[key] = requestCount;
    final isDrivers = options.path.endsWith('/drivers');
    final rows = requestCount == 1
        ? <dynamic>[]
        : <dynamic>[
            isDrivers
                ? {'driver_number': 4, 'last_name': 'Norris'}
                : {'driver_number': 4, 'lap_number': 1, 'lap_duration': 100.0},
          ];
    return ResponseBody.fromString(
      jsonEncode(rows),
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
  test(
    'reintenta 429, conserva filtros y cachea la lista durante 30 s',
    () async {
      final adapter = _RateLimitedAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = OpenF1Api(
        dio,
        baseUrl: 'https://example.test/v1',
        minimumRequestGap: Duration.zero,
        retryBaseDelay: Duration.zero,
      );

      final first = await api.getSessions(year: 2026, countryName: 'Singapore');
      final second = await api.getSessions(
        year: 2026,
        countryName: 'Singapore',
      );

      expect(first.single['session_key'], 42);
      expect(second, first);
      expect(adapter.requests, 2);
      expect(
        adapter.successfulRequest?.path,
        'https://example.test/v1/sessions',
      );
      expect(adapter.successfulRequest?.queryParameters, {
        'year': 2026,
        'country_name': 'Singapore',
      });
    },
  );

  test('no cachea listas vacías de vueltas ni pilotos', () async {
    final adapter = _EmptyThenDataAdapter();
    final api = OpenF1Api(
      Dio()..httpClientAdapter = adapter,
      baseUrl: 'https://example.test/v1',
      minimumRequestGap: Duration.zero,
    );

    expect(await api.getLaps(77), isEmpty);
    expect(await api.getLaps(77), hasLength(1));
    expect(await api.getSessionDrivers(77), isEmpty);
    expect(await api.getSessionDrivers(77), hasLength(1));

    expect(adapter.requests.values, everyElement(2));
  });
}
