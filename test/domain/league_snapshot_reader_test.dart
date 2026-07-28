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

  test('el resumen del último GP usa puntos y posición de esa carrera', () {
    final raw = jsonEncode({
      'leagues': {
        'Data': {
          'Value': {
            'user_leagues': [
              {
                'league_id': 20,
                'league_name': 'Liga',
                'league_type': 'Private',
                'member_count': 2,
              },
            ],
          },
        },
      },
      'leaderboards': {
        '20': {
          'rounds': {
            '4': {
              'Value': {
                'leaderboard': [
                  {
                    'cur_rank': 1,
                    'cur_points': 900,
                    'rank': 2,
                    'race_rank': 1,
                    'event_points': 210,
                    'team_name': 'Ganador GP',
                  },
                  {
                    'cur_rank': 2,
                    'cur_points': 850,
                    'rank': 1,
                    'race_rank': 2,
                    'event_points': 180,
                    'team_name': 'Segundo GP',
                  },
                ],
              },
            },
          },
        },
      },
    });

    final result = LeagueSnapshotReader.latestGp(raw);

    expect(result!.standings.first.name, 'Ganador GP');
    expect(result.standings.first.rank, 1);
    expect(result.standings.first.points, 210);
  });
}
