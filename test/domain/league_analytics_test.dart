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
                'member': [
                  {
                    'userGuid': 'a',
                    'teamName': 'Equipo A',
                    'gamedaypoints': 100,
                  },
                  {
                    'userGuid': 'b',
                    'teamName': 'Equipo B',
                    'gamedaypoints': 80,
                  },
                ],
              },
            },
          },
          '2': {
            'Data': {
              'Value': {
                'member': [
                  {
                    'userGuid': 'a',
                    'teamName': 'Equipo A',
                    'gamedaypoints': 50,
                  },
                  {
                    'userGuid': 'b',
                    'teamName': 'Equipo B',
                    'gamedaypoints': 90,
                  },
                ],
              },
            },
          },
        },
      },
      'leaderboards': {
        'league-1': {
          'member': [
            {
              'userGuid': 'b',
              'teamName': 'Equipo B',
              'userRank': 1,
              'ovPoints': 170
            },
            {
              'userGuid': 'a',
              'teamName': 'Equipo A',
              'userRank': 2,
              'ovPoints': 150
            },
          ],
        },
      },
    };

    final analytics = LeagueAnalytics.fromSnapshot(snapshot, 'league-1');

    expect(
        analytics.events.map((event) => event.label), ['Australia', 'China']);
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
}
