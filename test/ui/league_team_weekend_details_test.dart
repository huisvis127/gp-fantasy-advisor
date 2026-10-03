import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gp_fantasy_advisor/core/league_colors.dart';
import 'package:gp_fantasy_advisor/core/theme.dart';
import 'package:gp_fantasy_advisor/domain/models/league_team_details.dart';
import 'package:gp_fantasy_advisor/ui/widgets/league_team_weekend_details.dart';

void main() {
  testWidgets(
    'el equipo desplegado conserva color y muestra puntos del GP con x2',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      AppColors.brightness = Brightness.dark;
      const details = LeagueTeamDetails(
        gameDayId: 8,
        available: true,
        weekendPoints: 55,
        drivers: [
          LeagueTeamAssetDetails(
            assetId: 'driver',
            name: 'Piloto elegido',
            playerId: '7',
            points: 20,
            boostMultiplier: 2,
            isConstructor: false,
          ),
        ],
        constructors: [
          LeagueTeamAssetDetails(
            assetId: 'ferrari',
            name: 'Ferrari',
            playerId: '101',
            points: 15,
            boostMultiplier: 1,
            isConstructor: true,
          ),
        ],
      );

      Future<void> render(Color color) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: ListView(
                children: [
                  LeagueTeamStandingCard(
                    key: const ValueKey('team'),
                    name: 'Equipo elegido',
                    rank: 2,
                    totalPoints: 400,
                    color: color,
                    details: details,
                    onChooseColor: () {},
                    onRefresh: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render(LeagueColors.palette[29].color);
      expect(find.text('Fin de semana: 55 pts'), findsOneWidget);
      expect(find.text('Temporada: 400 pts'), findsOneWidget);
      await tester.tap(find.text('Equipo elegido'));
      await tester.pumpAndSettle();
      expect(find.text('Piloto elegido'), findsOneWidget);
      expect(find.text('40 pts'), findsOneWidget);
      expect(find.text('15 pts'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      final nextColor = LeagueColors.palette[35].color;
      await render(nextColor);
      for (final label in [
        '#2',
        'Equipo elegido',
        'Piloto elegido',
        'Ferrari',
        '40 pts',
        '15 pts',
      ]) {
        expect(
          tester.widget<Text>(find.text(label)).style!.color,
          LeagueColors.textColor(nextColor, Brightness.dark),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}
