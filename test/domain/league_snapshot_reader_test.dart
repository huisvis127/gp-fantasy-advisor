import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/services/league_snapshot_reader.dart';

void main() {
  test('elige la liga activa y la última jornada con clasificación', () {
    final raw = jsonEncode({
      'leagues': {
        'Data': {
          'Value': {
            'user_leagues': [
              {
                'league_id': 10,
                'league_name': 'Otra%20Liga',
                'league_type': 'Private',
                'member_count': 4,
              },
              {
                'league_id': 20,
                'league_name': 'Liga%20Elegida',
                'league_type': 'Private',
                'member_count': 3,
              },
            ],
          },
        },
      },
      'leaderboards': {
        '20': {
          'rounds': {
            '1': {
              'Value': {
                'leaderboard': [
                  {
                    'cur_rank': 1,
                    'team_name': 'Equipo%20Uno',
                    'cur_points': 120,
                  },
                ],
              },
            },
            '2': {
              'Value': {
                'leaderboard': [
                  {
                    'cur_rank': 1,
                    'team_name': 'Equipo%20Dos',
                    'cur_points': 215.5,
                  },
                  {
                    'cur_rank': 2,
                    'team_name': 'Equipo%20Uno',
                    'cur_points': 190,
                  },
                ],
              },
            },
            '3': {
              'Value': {'leaderboard': <Object>[]},
            },
          },
        },
      },
    });

    final result = LeagueSnapshotReader.latestGp(
      raw,
      selectedLeagueId: '20',
    );

    expect(result, isNotNull);
    expect(result!.leagueName, 'Liga Elegida');
    expect(result.round, 2);
    expect(result.standings, hasLength(2));
    expect(result.standings.first.name, 'Equipo Dos');
    expect(result.standings.first.points, 215.5);
  });

  test('limpia porcentajes y signos de suma en nombres', () {
    expect(cleanFantasyName('Mi%20Equipo+F1'), 'Mi Equipo F1');
  });
}
