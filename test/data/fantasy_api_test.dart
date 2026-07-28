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
    final payload = options.path.contains('raceday_en.json')
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
                  'GamedayPoints': 52,
                },
                {
                  'PlayerId': '101',
                  'Skill': 2,
                  'PositionName': 'CONSTRUCTOR',
                  'Value': 28.0,
                  'FUllName': 'Mercedes',
                  'TeamName': 'Mercedes',
                  'GamedayPoints': 115,
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

  test('lee directamente los puntos oficiales de una jornada histórica',
      () async {
    final adapter = _FeedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = FantasyApi(dio, publicBaseUrl: 'https://fantasy.formula1.com');

    final assets = await api.getGameDayAssets(7);

    expect(adapter.paths, hasLength(1));
    expect(adapter.paths.single, endsWith('/feeds/drivers/7_en.json'));
    expect(assets.first['canonical_id'], 'antonelli');
    expect(assets.first['GamedayPoints'], 52);
    expect(assets.last['GamedayPoints'], 115);
  });
}
