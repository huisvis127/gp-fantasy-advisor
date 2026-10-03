import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/league_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeagueColors', () {
    test(
      'offers combined neon and normal colors without losing previous colors',
      () {
        const palette = LeagueColors.palette;

        expect(palette, hasLength(40));
        expect(palette.map((choice) => choice.name).toSet(), hasLength(40));
        expect(
          palette.map((choice) => choice.color.toARGB32()).toSet(),
          hasLength(40),
        );
        expect(palette.every((choice) => choice.name.isNotEmpty), isTrue);
        expect(palette.where((choice) => choice.isNeon), hasLength(20));
        expect(palette.where((choice) => !choice.isNeon), hasLength(20));
        expect(LeagueColors.displayOrder.take(4), [20, 0, 21, 1]);
        expect(
          LeagueColors.resolve('league', 'member:1', {'member': 7}),
          palette[7].color,
        );
        expect(
          palette[LeagueColors.indexForIdentity('league', 'member')].isNeon,
          isTrue,
        );
      },
    );

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
