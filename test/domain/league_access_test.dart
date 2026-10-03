import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/league_access.dart';
import 'package:gp_fantasy_advisor/domain/models/league_analytics.dart';

void main() {
  test('analytics does not process a blocked league or oversized history', () {
    final largeBoard = {
      'memRank': [
        for (var i = 0; i < 1000; i++) {'userGuid': 'u$i', 'gdPoints': 1},
      ],
    };
    expect(
      LeagueAnalytics.fromSnapshot({
        'leaderboards': {'large': largeBoard},
        'leagueHistory': {
          'large': {'1': largeBoard},
        },
      }, 'large').members,
      isEmpty,
    );
    expect(
      LeagueAnalytics.fromSnapshot({
        'leaderboards': {
          'small': {
            'memRank': [
              {'userGuid': 'u0'},
            ],
          },
        },
        'leagueHistory': {
          'small': {'1': largeBoard},
        },
      }, 'small').events,
      hasLength(1),
    );
  });
  for (final count in [19, 20, 21, 100, 50000]) {
    test('checks metadata for $count teams before looking at rows', () {
      final access = LeagueAccess.inspect(league: {'TotalMembers': count});
      expect(access.isBlocked, count > 20);
      expect(access.teamCount, count);
    });
  }
  test('counts current teams, ignores capacity and historical rosters', () {
    final rows = [
      for (var i = 0; i < 20; i++) {'userGuid': 'u$i', 'team_no': 1},
    ];
    expect(
      LeagueAccess.inspect(
        league: {'MaxMembers': 500},
        board: {
          'current': {
            'Value': {'memRank': rows, 'userRank': rows},
          },
          'rounds': {
            '1': {'memRank': List.filled(1000, {})},
          },
        },
      ).isBlocked,
      false,
    );
    expect(
      LeagueAccess.inspect(
        league: {'teamCount': 20},
        board: {
          'memRank': [
            ...rows,
            {'userGuid': 'another', 'team_no': 1},
          ],
        },
      ).isBlocked,
      true,
    );
  });
  test(
    'uses nested totals even when the returned page has only twenty rows',
    () {
      expect(
        LeagueAccess.inspect(
          league: {},
          board: {
            'Value': {
              'total_records': 5000,
              'leaderboard': List.filled(20, {}),
            },
          },
        ).teamCount,
        5000,
      );
      expect(
        LeagueAccess.inspect(
          league: {},
          capturedAccess: {'teamCount': 21, 'blocked': true},
        ).isBlocked,
        true,
      );
      expect(LeagueAccess.inspect(league: {}).teamCount, isNull);
    },
  );
}
