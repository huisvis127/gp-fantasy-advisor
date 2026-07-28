import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/sources/openf1_api.dart';

Map<String, dynamic> _lap(
  int number,
  double seconds, {
  bool pitOut = false,
}) =>
    {
      'driver_number': 4,
      'lap_number': number,
      'lap_duration': seconds,
      'is_pit_out_lap': pitOut,
    };

void main() {
  test('el ritmo usa tandas consecutivas y no las dos vueltas más rápidas', () {
    final api = OpenF1Api(Dio(), baseUrl: 'https://example.test');
    final result = api.aggregateStints(
      laps: [
        _lap(1, 110, pitOut: true),
        _lap(2, 100),
        _lap(3, 101),
        _lap(4, 102),
        _lap(5, 120), // cooldown: corta la tanda
        _lap(6, 111, pitOut: true),
        _lap(7, 99),
        _lap(8, 100),
        _lap(9, 101),
      ],
      season: 2026,
      round: 12,
      sessionKey: 'fp2',
    )[4.toString()]!;

    expect(result.bestLapMs, 99000);
    expect(result.bestStintAvgMs, 100000);
    expect(result.top2StintsAvgMs, 100500);
    expect(result.lapCount, 7);
  });

  test('usa respaldo estable si no hay tres vueltas limpias consecutivas', () {
    final api = OpenF1Api(Dio(), baseUrl: 'https://example.test');
    final result = api.aggregateStints(
      laps: [
        _lap(1, 100),
        _lap(3, 101),
      ],
      season: 2026,
      round: 12,
      sessionKey: 'fp1',
    )['4']!;

    expect(result.bestLapMs, 100000);
    expect(result.top2StintsAvgMs, 100500);
  });
}
