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
    final data = switch (options.path.split('/').last) {
      'sessions' => [
        _session(
          101,
          'Practice 1',
          '2026-10-09T08:00:00Z',
          '2026-10-09T09:00:00Z',
        ),
        _session(
          102,
          'Practice 2',
          '2026-10-09T12:00:00Z',
          '2026-10-09T13:00:00Z',
        ),
        _session(
          103,
          'Practice 3',
          '2026-10-10T08:00:00Z',
          '2026-10-10T09:00:00Z',
        ),
        _session(
          104,
          'Qualifying',
          '2026-10-10T12:00:00Z',
          '2026-10-10T13:00:00Z',
        ),
      ],
      'drivers' => [
        {
          'driver_number': 4,
          'last_name': 'Norris',
          'full_name': 'Lando NORRIS',
        },
      ],
      'laps' when options.queryParameters['session_key'] == 102 => null,
      'laps' when options.queryParameters['session_key'] == 103 => <dynamic>[],
      'laps' => [_lap(4, 100.0, 1), _lap(4, 101.0, 2), _lap(4, 102.0, 3)],
      _ => throw StateError('Unexpected OpenF1 path: ${options.path}'),
    };
    if (options.path.endsWith('/laps') &&
        options.queryParameters['session_key'] == 102) {
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
  test('un 404 en FP2 conserva FP1 e inyecta al piloto del catálogo', () async {
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
        round: 18,
        raceName: 'Singapore Grand Prix',
        circuitId: 'marina_bay',
        circuitName: 'Marina Bay',
        country: 'Singapore',
        date: DateTime.utc(2026, 10, 11, 12),
      ),
      now: DateTime.utc(2026, 10, 10, 10),
      catalog: {'norris': _driver('norris', 'Lando Norris')},
    );

    expect(weekend.sessions, {'fp1'});
    expect(weekend.stageLabel, 'CON FP1');
    expect(weekend.byDriverId.keys, {'norris'});
    expect(weekend.byDriverId['norris']!.keys, {'onelap:fp1', 'pace:fp1'});
    expect(weekend.error, contains('FP2 (HTTP 404'));
    expect(weekend.error, contains('FP3'));
    expect(weekend.error, contains('Singapore Grand Prix'));
    expect(adapter.requests.map((request) => request.path.split('/').last), [
      'sessions',
      'drivers',
      'laps',
      'laps',
      'laps',
    ]);
  });
}
