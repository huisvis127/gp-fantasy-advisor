import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/league_analytics.dart';

void main() {
  for (final count in [0, 19, 20, 21, 100]) {
    test(
      'limita una liga de $count equipos a veinte sin alterar los datos',
      () {
        final members = List.generate(count, (index) {
          return LeagueMemberTrend(key: '$index', name: 'Equipo $index')
            ..currentRank = index + 1
            ..cumulativePoints = [100.0, 200.0]
            ..positions = [count - index, index + 1]
            ..gold = 2;
        });
        final source = LeagueAnalytics(
          events: const [
            LeagueEvent(gameDayId: 1, label: 'GP1'),
            LeagueEvent(gameDayId: 2, label: 'GP2'),
          ],
          members: members,
        );

        final visible = source.limitedForDisplay;
        expect(visible.members.length, count > 20 ? 20 : count);
        expect(source.members, hasLength(count));
        expect(visible.events, same(source.events));
        expect(visible.members, orderedEquals(members.take(20)));
        if (count > 0) {
          expect(visible.members.first.currentRank, 1);
          expect(visible.members.first.positions, [count, 1]);
          expect(visible.members.first.gold, 2);
        }
      },
    );
  }
}
