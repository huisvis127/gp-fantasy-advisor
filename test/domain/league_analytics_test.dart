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
}
