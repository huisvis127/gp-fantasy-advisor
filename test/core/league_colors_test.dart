import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/league_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeagueColors', () {
    test('offers twenty distinct colors with Spanish names', () {
      const palette = LeagueColors.palette;

      expect(palette, hasLength(20));
      expect(palette.map((choice) => choice.name).toSet(), hasLength(20));
      expect(
        palette.map((choice) => choice.color.toARGB32()).toSet(),
        hasLength(20),
      );
      expect(palette.every((choice) => choice.name.isNotEmpty), isTrue);
    });

    test('fallback color stays stable for the same league and identity', () {
      final original = LeagueColors.indexForIdentity('league-42', 'team-123');
      final afterStandingsReorder = LeagueColors.indexForIdentity(
        'league-42',
        'team-123',
      );

      expect(afterStandingsReorder, original);
      expect(
        LeagueColors.indexForIdentity('league-42', 'team-456'),
        isNot(original),
      );
    });

    test('persists selections by league and member identity', () async {
      SharedPreferences.setMockInitialValues({});

      await LeagueColors.save('league-a', 'member-1', 7);
      await LeagueColors.save('league-a', 'member-2', 12);
      await LeagueColors.save('league-b', 'member-1', 3);

      expect(await LeagueColors.load('league-a'), {
        'member-1': 7,
        'member-2': 12,
      });
      expect(await LeagueColors.load('league-b'), {'member-1': 3});
    });
  });
}
