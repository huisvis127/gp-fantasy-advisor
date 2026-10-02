import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/league_analytics.dart';

void main() {
  test('construye puntos, posiciones y medallas por jornada', () {
    final snapshot = <String, dynamic>{
      'gameDay': 2,
      'leagueEvents': [
        {'gameDayId': 1, 'label': 'Australia'},
        {'gameDayId': 2, 'label': 'China'},
      ],
      'leagueHistory': {
        'league-1': {
          '1': {
            'Data': {
              'Value': {
                'memRank': [
                  {'userGuid': 'a', 'teamName': 'Equipo A', 'gdPoints': 100},
                  {'userGuid': 'b', 'teamName': 'Equipo B', 'gdPoints': 80},
                ],
              },
            },
          },
          '2': {
            'Data': {
              'Value': {
                'memRank': [
                  {'userGuid': 'a', 'teamName': 'Equipo A', 'gdPoints': 50},
                  {'userGuid': 'b', 'teamName': 'Equipo B', 'gdPoints': 90},
                ],
              },
            },
          },
        },
      },
      'leaderboards': {
        'league-1': {
          'memRank': [
            {
              'userGuid': 'b',
              'teamName': 'Equipo B',
              'userRank': 1,
              'ovPoints': 170,
            },
            {
              'userGuid': 'a',
              'teamName': 'Equipo A',
              'userRank': 2,
              'ovPoints': 150,
            },
          ],
        },
      },
    };

    final analytics = LeagueAnalytics.fromSnapshot(snapshot, 'league-1');

    expect(analytics.events.map((event) => event.label), [
      'Australia',
      'China',
    ]);
    expect(analytics.members, hasLength(2));
    final a = analytics.members.firstWhere((member) => member.key == 'a');
    final b = analytics.members.firstWhere((member) => member.key == 'b');
    expect(a.cumulativePoints, [100, 150]);
    expect(b.cumulativePoints, [80, 170]);
    expect(a.positions, [1, 2]);
    expect(b.positions, [2, 1]);
    expect(a.gold, 1);
    expect(b.gold, 1);
    expect(b.currentRank, 1);
  });

  test('acepta los feeds 2026 y conserva los cuatro equipos de la liga', () {
    Map<String, dynamic> row(String id, String name, int rank, num points) => {
      'user_guid': id,
      'team_name': name,
      'cur_rank': rank,
      'cur_points': points,
    };

    final snapshot = <String, dynamic>{
      'gameDay': 2,
      'leagueEvents': [
        {'gameDayId': 1, 'label': 'Australian GP', 'isComplete': true},
        {'gameDayId': 2, 'label': 'Chinese GP', 'isComplete': true},
      ],
      'leagueHistory': {
        '4764009': {
          '1': {
            'Value': {
              'leaderboard': [
                row('tx', 'Txarandaka%20Motorsport', 1, 191),
                row('luis', 'Luispeed', 2, 153),
                row('oro', 'OROICLE%20Roid%20Bull%20Racing', 3, 148),
                row('coponos', 'Coponos%20Racing', 4, 99),
              ],
            },
          },
          '2': {
            'Value': {
              'leaderboard': [
                row('luis', 'Luispeed', 1, 481),
                row('oro', 'OROICLE%20Roid%20Bull%20Racing', 1, 481),
                row('tx', 'Txarandaka%20Motorsport', 3, 365),
                row('coponos', 'Coponos%20Racing', 4, 338),
              ],
            },
          },
        },
      },
      'leaderboards': {
        '4764009': {
          'Value': {
            'leaderboard': [
              row('oro', 'OROICLE%20Roid%20Bull%20Racing', 1, 2131),
              {...row('luis', 'Luispeed', 2, 1974), 'isLoggedInUser': 1},
              row('tx', 'Txarandaka%20Motorsport', 3, 1961),
              row('coponos', 'Coponos%20Racing', 4, 1671),
            ],
          },
        },
      },
    };

    final analytics = LeagueAnalytics.fromSnapshot(snapshot, '4764009');

    expect(analytics.members, hasLength(4));
    expect(analytics.members.map((member) => member.name), [
      'OROICLE Roid Bull Racing',
      'Luispeed',
      'Txarandaka Motorsport',
      'Coponos Racing',
    ]);
    expect(analytics.members.map((member) => member.currentTotal), [
      2131,
      1974,
      1961,
      1671,
    ]);
    expect(
      analytics.members
          .firstWhere((member) => member.key == 'coponos')
          .positions,
      [4, 4],
    );
    expect(
      analytics.members.firstWhere((member) => member.key == 'luis').gold,
      1,
    );
    expect(
      analytics.members.firstWhere((member) => member.key == 'oro').gold,
      1,
    );
    expect(
      analytics.members.firstWhere((member) => member.key == 'tx').bronze,
      1,
    );
    expect(
      analytics.members
          .firstWhere((member) => member.key == 'luis')
          .isCurrentUser,
      isTrue,
    );
  });
  test('no fusiona dos equipos del mismo dueño ni sus puntos', () {
    final rows = [
      {
        'yuserGuid': 'owner',
        'teamno': 1,
        'teamName': 'Equipo 1',
        'ovRank': 1,
        'ovPoints': 90,
        'gdPoints': 30,
      },
      {
        'yuserGuid': 'owner',
        'teamno': 2,
        'teamName': 'Equipo 2',
        'ovRank': 2,
        'ovPoints': 70,
        'gdPoints': 10,
      },
    ];
    final result = LeagueAnalytics.fromSnapshot({
      'gameDay': 2,
      'leaderboards': {
        'l': {'memRank': rows},
      },
      'leagueHistory': {
        'l': {
          '2': {'memRank': rows},
        },
      },
    }, 'l');
    expect(result.members.map((member) => member.key), ['owner:1', 'owner:2']);
    expect(result.members.map((member) => member.currentTotal), [90, 70]);
    expect(result.members.map((member) => member.eventPoints.single), [30, 10]);
  });
  test(
    'cuatro equipos siguen siendo cuatro al mezclar GUID, social_id y team_no',
    () {
      final current = List.generate(
        4,
        (i) => <String, dynamic>{
          // El orden del JSON anterior favorecía social_id y rompía el cruce.
          'social_id': 'social-$i',
          'team_no': 1,
          'team_name': 'Equipo $i',
          'user_guid': 'guid-$i',
          'cur_rank': i + 1,
          'cur_points': 400 - i * 20,
        },
      );
      final historical = List.generate(
        4,
        (i) => <String, dynamic>{
          'userGuid': 'guid-$i',
          'teamName': 'Equipo $i',
          'gdPoints': 100 - i * 10,
        },
      );
      final older = List.generate(
        4,
        (i) => <String, dynamic>{
          'social_id': 'social-$i',
          'team_name': 'Equipo $i',
          'cur_points': 80 - i * 10,
        },
      );
      final result = LeagueAnalytics.fromSnapshot({
        'leaderboards': {
          'l': {
            'Value': {'leaderboard': current},
          },
        },
        'leagueHistory': {
          'l': {
            '1': {'memRank': older},
            '2': {'memRank': historical},
          },
        },
      }, 'l');
      expect(result.members, hasLength(4));
      expect(result.members.map((m) => m.key), [
        'guid-0:1',
        'guid-1:1',
        'guid-2:1',
        'guid-3:1',
      ]);
      expect(result.members.first.eventPoints, [80, 100]);
      expect(result.members.first.currentTotal, 400);
      expect(result.members.every((m) => m.currentTotal != null), isTrue);
    },
  );

  test(
    'no añade a la clasificación actual miembros de un historial antiguo',
    () {
      final result = LeagueAnalytics.fromSnapshot({
        'leaderboards': {
          'l': {
            'memRank': [
              {'userGuid': 'a', 'teamName': 'Actual', 'ovPoints': 90},
            ],
          },
        },
        'leagueHistory': {
          'l': {
            '1': {
              'memRank': [
                {'userGuid': 'a', 'teamName': 'Actual', 'gdPoints': 50},
                {'userGuid': 'gone', 'teamName': 'Anterior', 'gdPoints': 80},
              ],
            },
          },
        },
      }, 'l');
      expect(result.members.map((m) => m.key), ['a']);
      expect(result.members.single.currentTotal, 90);
    },
  );

  test('lee el historial current/rounds de las capturas Polewise previas', () {
    final row = {
      'user_guid': 'a',
      'team_no': 1,
      'team_name': 'A',
      'cur_points': 50,
    };
    final result = LeagueAnalytics.fromSnapshot({
      'leaderboards': {
        'l': {
          'current': {
            'Value': {
              'leaderboard': [
                {...row, 'cur_points': 150},
              ],
            },
          },
          'rounds': {
            '1': {
              'Value': {
                'leaderboard': [row],
              },
            },
          },
        },
      },
    }, 'l');
    expect(result.members, hasLength(1));
    expect(result.members.single.currentTotal, 150);
    expect(result.members.single.eventPoints, [50]);
  });
}
