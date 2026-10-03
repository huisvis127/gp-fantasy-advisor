import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/league_analytics.dart';
import 'package:gp_fantasy_advisor/domain/models/league_team_details.dart';

void main() {
  LeagueMemberTrend member(String key, {bool current = false}) =>
      LeagueMemberTrend(key: key, name: 'Equipo $key')..isCurrentUser = current;

  test('mapea el equipo por owner y teamno, con captain x2 una sola vez', () {
    final snapshot = <String, dynamic>{
      'gameDay': 5,
      'guid': 'me',
      'teams': {
        'Data': {
          'Value': [
            {'teamno': 1, 'teamname': 'Mi equipo 1'},
            {'teamno': 2, 'teamname': 'Mi equipo 2'},
          ],
        },
      },
      'teamDetails': {
        '1': {
          'Data': {
            'Value': {
              'userTeam': [
                {
                  'playerid': [10],
                },
              ],
            },
          },
        },
        '2': {
          'Data': {
            'Value': {
              'capPlayerId': 20,
              'userTeam': [
                {
                  'playerid': [
                    {'playerid': 20, 'iscaptain': 1, 'boostmultiplier': 2},
                    {'playerid': 21},
                    {'playerid': 30},
                  ],
                },
              ],
            },
          },
        },
      },
    };
    final assets = [
      _asset(10, 'wrong', 'Piloto equivocado', 5, 999),
      _asset(20, 'max_verstappen', 'Max Verstappen', 5, 0),
      _asset(21, 'lando_norris', 'Lando Norris', 5, -4),
      _asset(30, 'mclaren', 'McLaren', 5, 12, constructor: true),
    ];

    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      member('me:2', current: true),
      assets,
    );

    expect(details.available, isTrue);
    expect(details.teamNumber, 2);
    expect(details.gameDayId, 5);
    expect(details.teamName, 'Mi equipo 2');
    expect(details.drivers.map((asset) => asset.playerId), ['20', '21']);
    expect(details.constructors.single.assetId, 'mclaren');
    expect(details.drivers.first.points, 0);
    expect(details.drivers.first.boostMultiplier, 2);
    expect(details.drivers.first.boostedPoints, 0);
    expect(details.drivers[1].points, -4);
    expect(details.drivers[1].boostMultiplier, 1);
    expect(details.weekendPoints, 8);
  });

  test(
    'un rival sin captura queda sin alineación y no hereda el equipo propio',
    () {
      final snapshot = <String, dynamic>{
        'gameDay': 3,
        'teams': {
          'Value': [
            {'teamno': 1, 'yuserGuid': 'me', 'teamname': 'Mi equipo'},
          ],
        },
        'teamDetails': {
          '1': {
            'Data': {
              'Value': {
                'userTeam': [
                  {
                    'playerid': [10],
                  },
                ],
              },
            },
          },
        },
      };
      final details = LeagueTeamDetails.fromSnapshot(
        snapshot,
        'league',
        member('opponent'),
        [_asset(10, 'verstappen', 'Max Verstappen', 3, 20)],
      );

      expect(details.available, isFalse);
      expect(details.assets, isEmpty);
      expect(details.weekendPoints, isNull);
    },
  );

  test('usa el guid global y el nombre para elegir entre equipos propios', () {
    final snapshot = <String, dynamic>{
      'guid': 'me',
      'gameDay': 2,
      'teams': {
        'Value': [
          {'teamno': 1, 'teamname': 'Neon Keys Racing'},
          {'teamno': 2, 'teamname': 'Neon Keys Racing 2'},
        ],
      },
      'teamDetails': {
        '1': {
          'Data': {
            'Value': {
              'userTeam': [
                {
                  'playerid': [11],
                },
              ],
            },
          },
        },
        '2': {
          'Data': {
            'Value': {
              'userTeam': [
                {
                  'playerid': [22],
                },
              ],
            },
          },
        },
      },
    };

    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      LeagueMemberTrend(key: 'me', name: 'Neon Keys Racing 2')
        ..isCurrentUser = true,
      [
        _asset(11, 'wrong', 'Otro piloto', 2, 70),
        _asset(22, 'leclerc', 'Charles Leclerc', 2, 12),
      ],
    );

    expect(details.available, isTrue);
    expect(details.teamNumber, 2);
    expect(details.drivers.single.playerId, '22');
  });

  test(
    'usa roster rival guardado por liga y puntos explícitos del event board',
    () {
      final snapshot = <String, dynamic>{
        'gameDay': 4,
        'leagueTeamDetails': {
          'league': {
            'rival:2': {
              'gameDay': 4,
              'Data': {
                'Value': {
                  'userTeam': [
                    {
                      'playerid': [44],
                    },
                  ],
                },
              },
            },
          },
        },
        'leagueHistory': {
          'league': {
            '4': {
              'Data': {
                'Value': {
                  'leaderboard': [
                    {'userGuid': 'rival', 'teamNo': 2, 'cur_points': 0},
                  ],
                },
              },
            },
          },
        },
      };
      final details = LeagueTeamDetails.fromSnapshot(
        snapshot,
        'league',
        member('rival:2'),
        [_asset(44, 'alonso', 'Fernando Alonso', 4, 99)],
      );

      expect(details.available, isTrue);
      expect(details.userGuid, 'rival');
      expect(details.teamNumber, 2);
      expect(details.drivers.single.points, 99);
      // Un cero explícito del event board prevalece sobre la suma del roster.
      expect(details.weekendPoints, 0);
    },
  );

  test('mega captain x3 respeta total cero de la fila yuserGuid', () {
    final snapshot = <String, dynamic>{
      'gameDay': 4,
      'leagueTeamDetails': {
        'league': {
          'rival': {
            'gameDay': 4,
            'Data': {
              'Value': {
                'mgCapPlayerId': 88,
                'userTeam': [
                  {
                    'playerid': [
                      {'playerid': 88, 'ismegacaptain': true},
                      {'playerid': 89, 'boostmultiplier': 2},
                    ],
                  },
                ],
              },
            },
          },
        },
      },
      'leagueHistory': {
        'league': {
          '4': {
            'Data': {
              'Value': {
                'leaderboard': [
                  {'yuserGuid': 'rival', 'gdpoints': 0},
                ],
              },
            },
          },
        },
      },
    };
    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      member('rival'),
      [
        _asset(88, 'hamilton', 'Lewis Hamilton', 4, 10),
        _asset(89, 'norris', 'Lando Norris', 4, 5),
      ],
    );

    final megaCaptain = details.drivers.firstWhere(
      (asset) => asset.playerId == '88',
    );
    final explicitBoost = details.drivers.firstWhere(
      (asset) => asset.playerId == '89',
    );
    expect(megaCaptain.boostMultiplier, 3);
    expect(megaCaptain.boostedPoints, 30);
    expect(explicitBoost.boostMultiplier, 2);
    expect(details.weekendPoints, 0);
  });

  test('mantiene puntos desconocidos null y no usa total de temporada', () {
    final snapshot = <String, dynamic>{
      'gameDay': 6,
      'teams': {
        'Value': [
          {'teamno': 1, 'yuserGuid': 'me', 'teamname': 'Mi equipo'},
        ],
      },
      'teamDetails': {
        '1': {
          'Data': {
            'Value': {
              'userTeam': [
                {
                  'playerid': [60, 61],
                },
              ],
            },
          },
        },
      },
      'leaderboards': {
        'league': {
          'Value': {
            'leaderboard': [
              {'userGuid': 'me', 'cur_points': 1234, 'ovpoints': 1234},
            ],
          },
        },
      },
    };
    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      member('me'),
      [
        _asset(60, 'perez', 'Sergio Perez', 6, 8),
        _asset(61, 'russell', 'George Russell', 5, 90),
      ],
    );

    expect(details.drivers.first.points, 8);
    expect(details.drivers.last.points, isNull);
    expect(details.weekendPoints, isNull);
  });

  test('una captura de GP anterior solo usa puntos de ese mismo GP', () {
    final snapshot = <String, dynamic>{
      'gameDay': 8,
      'leagueTeamDetails': {
        'league': {
          'rival': {
            'gameDay': 7,
            'Data': {
              'Value': {
                'userTeam': [
                  {
                    'playerid': [77],
                  },
                ],
              },
            },
          },
        },
      },
    };
    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      member('rival'),
      [_asset(77, 'sainz', 'Carlos Sainz', 8, 99)],
    );

    expect(details.gameDayId, 7);
    expect(details.available, isTrue);
    expect(details.drivers.single.points, isNull);
    expect(details.weekendPoints, isNull);
  });

  test('no usa puntos ambiguos entre filas con el mismo yuserGuid', () {
    final snapshot = <String, dynamic>{
      'gameDay': 9,
      'leagueTeamDetails': {
        'league': {
          'same-owner': {
            'gameDay': 9,
            'Data': {
              'Value': {
                'userTeam': [
                  {
                    'playerid': [99],
                  },
                ],
              },
            },
          },
        },
      },
      'leagueHistory': {
        'league': {
          '9': {
            'Data': {
              'Value': {
                'leaderboard': [
                  {
                    'yuserGuid': 'same-owner',
                    'team_name': 'Neon A',
                    'gdpoints': 120,
                  },
                  {
                    'yuserGuid': 'same-owner',
                    'team_name': 'Neon B',
                    'gdpoints': 80,
                  },
                ],
              },
            },
          },
        },
      },
    };
    final details = LeagueTeamDetails.fromSnapshot(
      snapshot,
      'league',
      member('same-owner'),
      [_asset(99, 'alonso', 'Fernando Alonso', 8, 15)],
    );

    expect(details.available, isTrue);
    expect(details.weekendPoints, isNull);
  });
}

Map<String, dynamic> _asset(
  int id,
  String canonicalId,
  String name,
  int round,
  num points, {
  bool constructor = false,
}) => {
  'id': '$id',
  'PlayerId': id,
  'canonical_id': canonicalId,
  'display_name': name,
  'is_constructor': constructor,
  'round': round,
  'GamedayPoints': points,
};
