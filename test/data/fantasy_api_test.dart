import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/sources/fantasy_api.dart';
import 'package:gp_fantasy_advisor/domain/models/fantasy_price.dart';

class _FeedAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    final payload = options.path.contains('/privateleague/list_1_')
        ? {
            'Value': {
              'leaderboard': [
                {'user_guid': 'a', 'team_no': 1, 'cur_points': 100},
              ],
            },
          }
        : options.path.contains('raceday_en.json')
        ? {
            'Data': {
              'fixtures': [
                {'GamedayId': 10, 'GDIsCurrent': 1},
              ],
            },
          }
        : {
            'Data': {
              'Value': [
                {
                  'PlayerId': '7',
                  'Skill': 1,
                  'PositionName': 'DRIVER',
                  'Value': 30.0,
                  'FUllName': 'Andrea Kimi Antonelli',
                  'TeamName': 'Mercedes',
                },
                {
                  'PlayerId': '101',
                  'Skill': 2,
                  'PositionName': 'CONSTRUCTOR',
                  'Value': 28.0,
                  'FUllName': 'Mercedes',
                  'TeamName': 'Mercedes',
                },
              ],
            },
          };
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

void main() {
  test('lee precios oficiales del feed de la jornada actual', () async {
    final adapter = _FeedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = FantasyApi(dio, publicBaseUrl: 'https://fantasy.formula1.com');

    final prices = await api.getCurrentPrices(2026);

    expect(adapter.paths, hasLength(2));
    expect(adapter.paths.last, endsWith('/feeds/drivers/10_en.json'));
    expect(prices, hasLength(2));
    expect(prices.first.assetId, 'antonelli');
    expect(prices.first.priceMillions, 30);
    expect(prices.last.assetId, 'mercedes');
    expect(prices.last.assetType, FantasyAssetType.constructor);
  });

  test('normaliza el catálogo conservando el id oficial', () async {
    final adapter = _FeedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = FantasyApi(dio, publicBaseUrl: 'https://fantasy.formula1.com');

    final assets = await api.getPlayersRaw(2026);

    expect(assets.first['id'], '7');
    expect(assets.first['canonical_id'], 'antonelli');
    expect(assets.last['is_constructor'], isTrue);
    expect(assets.last['price'], 28.0);
  });

  test('descarga precio y puntos de las tres jornadas recientes', () async {
    final adapter = _FeedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = FantasyApi(dio, publicBaseUrl: 'https://fantasy.formula1.com');

    final snapshots = await api.getRecentRoundSnapshots(2026);

    expect(snapshots.map((item) => item.round), [8, 9, 10]);
    expect(snapshots.last.isCurrent, isTrue);
    expect(snapshots.first.prices, hasLength(2));
    expect(snapshots.first.points, hasLength(2));
    expect(adapter.paths, hasLength(4));
  });

  test(
    'construye la clasificación provisional desde el feed oficial',
    () async {
      final adapter = _FeedAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = FantasyApi(
        dio,
        publicBaseUrl: 'https://fantasy.formula1.com',
      );

      final live = await api.getLiveSnapshot(2026);

      expect(live.round, 10);
      expect(live.assets, hasLength(2));
      expect(live.assets.first.assetId, 'antonelli');
    },
  );
  test(
    'el detalle usa el GP capturado aunque el calendario esté en otro',
    () async {
      final adapter = _FeedAdapter();
      final api = FantasyApi(
        Dio()..httpClientAdapter = adapter,
        publicBaseUrl: 'https://fantasy.formula1.com',
      );
      final assets = await api.getGameDayAssets(7);
      expect(adapter.paths, [
        'https://fantasy.formula1.com/feeds/drivers/7_en.json',
      ]);
      expect(assets.every((asset) => asset['round'] == 7), isTrue);
    },
  );
  test('la liga actual usa el feed oficial en vez del endpoint legacy', () async {
    final adapter = _FeedAdapter();
    final api = FantasyApi(
      Dio()..httpClientAdapter = adapter,
      publicBaseUrl: 'https://fantasy.formula1.com',
    );
    final board = await api.getPrivateLeagueStandings('4764009');
    expect(adapter.paths, [
      'https://fantasy.formula1.com/feeds/leaderboard/privateleague/list_1_4764009_0_1.json',
    ]);
    expect(board['Value']['leaderboard'], hasLength(1));
  });
}
