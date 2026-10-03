import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/data/repositories/team_import_service.dart';
import 'package:gp_fantasy_advisor/data/sources/fantasy_api.dart';
import 'package:gp_fantasy_advisor/data/sources/fantasy_auth_service.dart';

class _AssetsAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = options.path.endsWith('raceday_en.json')
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
                for (var id = 1; id <= 5; id++)
                  {
                    'PlayerId': '$id',
                    'Skill': 1,
                    'PositionName': 'DRIVER',
                    'FUllName': switch (id) {
                      1 => 'Max Verstappen',
                      2 => 'Lando Norris',
                      3 => 'Charles Leclerc',
                      4 => 'Lewis Hamilton',
                      _ => 'Oscar Piastri',
                    },
                    'TeamName': 'Team $id',
                  },
                {
                  'PlayerId': '101',
                  'Skill': 2,
                  'PositionName': 'CONSTRUCTOR',
                  'FUllName': 'McLaren',
                  'TeamName': 'McLaren',
                },
                {
                  'PlayerId': '102',
                  'Skill': 2,
                  'PositionName': 'CONSTRUCTOR',
                  'FUllName': 'Ferrari',
                  'TeamName': 'Ferrari',
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('importa capPlayerId y lo prefiere a mgCapPlayerId', () async {
    const storageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final snapshot = {
      'teamDetails': {
        '1': {
          'Data': {
            'Value': {
              'capPlayerId': 2,
              'mgCapPlayerId': 1,
              'userTeam': [
                {
                  'playerid': [
                    for (var id = 1; id <= 5; id++) {'playerid': id},
                    {'playerid': 101},
                    {'playerid': 102},
                  ],
                },
              ],
            },
          },
        },
      },
    };
    final storedValues = <String, String>{
      'f1_fantasy_web_snapshot': jsonEncode(snapshot),
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = call.arguments as Map?;
          final key = args?['key']?.toString();
          if (call.method == 'read') return storedValues[key];
          if (call.method == 'write') {
            storedValues[key!] = args!['value'].toString();
          }
          if (call.method == 'delete') storedValues.remove(key);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, null),
    );

    final dio = Dio()..httpClientAdapter = _AssetsAdapter();
    final service = TeamImportService(
      api: FantasyApi(dio, publicBaseUrl: 'https://fantasy.formula1.com'),
      auth: FantasyAuthService(
        dio,
        loginBaseUrl: 'https://fantasy.formula1.com',
        storage: const FlutterSecureStorage(),
      ),
    );

    final team = await service.importMyTeam(
      season: 2026,
      driverCatalog: const {
        'max_verstappen': 'Max Verstappen',
        'lando_norris': 'Lando Norris',
        'charles_leclerc': 'Charles Leclerc',
        'lewis_hamilton': 'Lewis Hamilton',
        'oscar_piastri': 'Oscar Piastri',
      },
      constructorCatalog: const {'mclaren': 'McLaren', 'ferrari': 'Ferrari'},
    );

    expect(team.boostedDriverId, 'lando_norris');
    expect(team.driverIds, hasLength(5));
    expect(team.constructorIds, ['mclaren', 'ferrari']);
  });
}
