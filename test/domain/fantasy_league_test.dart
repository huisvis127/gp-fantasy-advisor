import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/fantasy_league.dart';

void main() {
  test('conserva todos los equipos aunque el servidor los llame standings', () {
    final entries = FantasyLeagueEntry.fromLeaderboardResponse({
      'data': {
        'standings': [
          {
            'entry_id': 1,
            'rank': 2,
            'team_name': 'Box Box Box',
            'manager_name': 'Ana',
            'points': 80,
          },
          {
            'entry_id': 2,
            'rank': 1,
            'team_name': 'Pole Position',
            'manager_name': 'Luis',
            'total_points': 90,
          },
        ],
      },
    });

    expect(entries, hasLength(2));
    expect(
      entries.map((entry) => entry.teamName),
      containsAll(['Box Box Box', 'Pole Position']),
    );
    expect(entries.first.rank, 1);
  });

  test('admite las variantes de liga de la API', () {
    final leagues = FantasyLeague.fromEntrantsResponse({
      'data': {
        'league_entrants': [
          {'leagueId': 'private-7', 'leagueName': 'Amigos', 'members_count': 4},
        ],
      },
    });
    expect(leagues.single.id, 'private-7');
    expect(leagues.single.memberCount, 4);
  });

  test('extrae integrantes, chips usados e historial de posiciones', () {
    final entry = FantasyLeagueEntry.fromLeaderboardResponse({
      'standings': [
        {
          'entry_id': 'team-1',
          'team_name': 'Safety Car',
          'rank': 2,
          'team': {
            'players': [
              {'id': 'norris', 'name': 'Lando Norris', 'type': 'driver'},
              {'id': 'mclaren', 'name': 'McLaren', 'is_constructor': true},
            ],
            'chips_used': ['Triple Boost', 'wildcard'],
          },
          'rank_history': [
            {'round': 1, 'rank': 3, 'label': 'AUS'},
            {'round': 2, 'rank': 2, 'label': 'CHN'},
          ],
        },
      ],
    }).single;

    expect(entry.members, hasLength(2));
    expect(entry.members.last.isConstructor, isTrue);
    expect(entry.chipsUsed, containsAll(['triple_boost', 'wildcard']));
    expect(entry.positionHistory.map((point) => point.rank), [3, 2]);
  });
}
