import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/fantasy_standings_provider.dart';
import 'package:gp_fantasy_advisor/core/weekend_provider.dart';
import 'package:gp_fantasy_advisor/data/sources/openf1_api.dart';
import 'package:gp_fantasy_advisor/domain/models/race.dart';

class _WeekendAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/sessions') &&
        options.queryParameters['country_name'] == 'Malaysia') {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'No sessions found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final data = switch (options.path.split('/').last) {
      'sessions' => [
        _session(
          11700,
          'Practice 1',
          '2026-09-28T06:30:00Z',
          '2026-09-28T07:30:00Z',
        ),
        _session(
          11727,
          'Practice 1',
          '2026-10-02T06:30:00Z',
          '2026-10-02T07:30:00Z',
        ),
        _session(
          11728,
          'Practice 2',
          '2026-10-02T10:00:00Z',
          '2026-10-02T11:00:00Z',
        ),
        _session(
          11729,
          'Practice 3',
          '2026-10-03T06:30:00Z',
          '2026-10-03T07:30:00Z',
        ),
        _session(
          11730,
          'Qualifying',
          '2026-10-03T10:00:00Z',
          '2026-10-03T11:00:00Z',
        ),
        _session(
          11732,
          'Practice 1',
          '2026-10-05T06:30:00Z',
          '2026-10-05T07:30:00Z',
        ),
      ],
      'drivers' => [
        {
          'driver_number': 4,
          'last_name': 'Norris',
          'full_name': 'Lando NORRIS',
        },
      ],
      'laps' when options.queryParameters['session_key'] == 11728 => null,
      'laps' when options.queryParameters['session_key'] == 11729 =>
        <dynamic>[],
      'laps' => [_lap(4, 100.0, 1), _lap(4, 101.0, 2), _lap(4, 102.0, 3)],
      _ => throw StateError('Unexpected OpenF1 path: ${options.path}'),
    };
    if (options.path.endsWith('/laps') &&
        options.queryParameters['session_key'] == 11728) {
      return ResponseBody.fromString(
        jsonEncode({'detail': 'Not found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _SessionCatalogUnavailableAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({'detail': 'Not found'}),
    404,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _session(int key, String name, String start, String end) =>
    {
      'session_key': key,
      'session_name': name,
      'date_start': start,
      'date_end': end,
    };

Map<String, dynamic> _lap(int driver, double seconds, int lapNumber) => {
  'driver_number': driver,
  'lap_number': lapNumber,
  'lap_duration': seconds,
  'is_pit_out_lap': false,
};

FantasyAssetInfo _driver(String id, String name) => FantasyAssetInfo(
  id: id,
  name: name,
  teamName: 'McLaren',
  position: 1,
  seasonPoints: 0,
  wins: 0,
  priceMillions: 25,
  expectedPoints: 20,
  kind: FantasyAssetKind.driver,
);

void main() {
  test('informa si falla el catálogo anual de sesiones', () async {
    final api = OpenF1Api(
      Dio()..httpClientAdapter = _SessionCatalogUnavailableAdapter(),
      baseUrl: 'https://example.test/v1',
      minimumRequestGap: Duration.zero,
    );
    final weekend = await loadWeekendData(
      api: api,
      race: Race(
        season: 2026,
        round: 16,
        raceName: 'Bahrain Grand Prix in Malaysia',
        circuitId: 'sepang',
        circuitName: 'Sepang International Circuit',
        country: 'Malaysia',
        date: DateTime.utc(2026, 10, 4, 9),
      ),
      now: DateTime.utc(2026, 10, 3, 8),
      catalog: {'norris': _driver('norris', 'Lando Norris')},
    );

    expect(weekend.isEmpty, isTrue);
    expect(weekend.error, contains('catálogo de sesiones'));
    expect(
      weekend.error,
      contains('Bahrain Grand Prix in Malaysia (Malaysia)'),
    );
    expect(weekend.error, contains('HTTP 404 en /v1/sessions'));
  });

  test('el 404 de Malaysia usa sesiones del año y conserva FP1', () async {
    final adapter = _WeekendAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = OpenF1Api(
      dio,
      baseUrl: 'https://example.test/v1',
      minimumRequestGap: Duration.zero,
    );
    final weekend = await loadWeekendData(
      api: api,
      race: Race(
        season: 2026,
        round: 16,
        raceName: 'Bahrain Grand Prix in Malaysia',
        circuitId: 'sepang',
        circuitName: 'Sepang International Circuit',
        country: 'Malaysia',
        date: DateTime.utc(2026, 10, 4, 9),
      ),
      now: DateTime.utc(2026, 10, 3, 8),
      catalog: {'norris': _driver('norris', 'Lando Norris')},
    );

    expect(weekend.sessions, {'fp1'});
    expect(weekend.stageLabel, 'CON FP1');
    expect(weekend.byDriverId.keys, {'norris'});
    expect(weekend.byDriverId['norris']!.keys, {'onelap:fp1', 'pace:fp1'});
    expect(weekend.error, contains('FP2 (HTTP 404'));
    expect(weekend.error, contains('FP3'));
    expect(weekend.error, contains('Bahrain Grand Prix in Malaysia'));
    expect(adapter.requests.map((request) => request.path.split('/').last), [
      'sessions',
      'sessions',
      'drivers',
      'laps',
      'laps',
      'laps',
    ]);
    expect(adapter.requests[0].queryParameters['country_name'], 'Malaysia');
    expect(adapter.requests[1].queryParameters, {'year': 2026});
  });
}
