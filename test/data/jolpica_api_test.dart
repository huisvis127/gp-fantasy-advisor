import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/sources/jolpica_api.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.payload);

  final Map<String, dynamic> payload;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_StubAdapter adapter) => Dio()..httpClientAdapter = adapter;

Map<String, dynamic> _mrData(List<Map<String, dynamic>> races) => {
      'MRData': {
        'RaceTable': {'Races': races},
      },
    };

void main() {
  test('getSeasonResults agrupa todas las rondas en una petición', () async {
    final adapter = _StubAdapter(_mrData([
      {
        'round': '1',
        'Results': [
          {
            'position': '1',
            'grid': '2',
            'status': 'Finished',
            'Driver': {'driverId': 'driver_a'},
            'Constructor': {'constructorId': 'team_a'},
            'FastestLap': {'rank': '1'},
          },
        ],
      },
      {
        'round': '2',
        'Results': [
          {
            'position': '2',
            'grid': '1',
            'status': 'Finished',
            'Driver': {'driverId': 'driver_b'},
            'Constructor': {'constructorId': 'team_b'},
          },
        ],
      },
    ]));
    final api =
        JolpicaApi(_dioWith(adapter), baseUrl: 'https://example.test/f1');

    final rows = await api.getSeasonResults(2026);

    expect(rows, hasLength(2));
    expect(rows.map((r) => r.round), [1, 2]);
    expect(rows.first.fastestLap, isTrue);
    expect(
        adapter.lastRequest?.path, 'https://example.test/f1/2026/results.json');
    expect(adapter.lastRequest?.queryParameters['limit'], 2000);
  });

  test('getSeasonQualifying conserva ronda y tiempos', () async {
    final adapter = _StubAdapter(_mrData([
      {
        'round': '4',
        'QualifyingResults': [
          {
            'position': '3',
            'Driver': {'driverId': 'driver_c'},
            'Q1': '1:22.100',
            'Q2': '1:21.900',
            'Q3': '1:21.500',
          },
        ],
      },
    ]));
    final api =
        JolpicaApi(_dioWith(adapter), baseUrl: 'https://example.test/f1');

    final rows = await api.getSeasonQualifying(2026);

    expect(rows.single.round, 4);
    expect(rows.single.driverId, 'driver_c');
    expect(rows.single.reachedQ3, isTrue);
    expect(adapter.lastRequest?.path,
        'https://example.test/f1/2026/qualifying.json');
  });
}
