import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gp_fantasy_advisor/core/app_providers.dart';
import 'package:gp_fantasy_advisor/core/league_colors.dart';
import 'package:gp_fantasy_advisor/core/league_team_details_provider.dart';
import 'package:gp_fantasy_advisor/core/providers.dart';
import 'package:gp_fantasy_advisor/core/theme.dart';
import 'package:gp_fantasy_advisor/data/sources/fantasy_auth_service.dart';
import 'package:gp_fantasy_advisor/domain/models/live_fantasy.dart';
import 'package:gp_fantasy_advisor/domain/models/my_team.dart';
import 'package:gp_fantasy_advisor/ui/screens/league/league_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SavedAuth extends FantasyAuthService {
  _SavedAuth(this.snapshot)
    : super(Dio(), loginBaseUrl: 'https://example.test');
  final Map<String, dynamic> snapshot;
  @override
  Future<String?> readStoredToken() async => null;
  @override
  Future<String?> readSessionSnapshot() async => jsonEncode(snapshot);
}

class _NoTeam extends MyTeamNotifier {
  @override
  Future<MyTeam?> build() async => null;
}

void main() {
  testWidgets(
    'elegir color actualiza clasificación, dos gráficas y medallero',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      AppColors.brightness = Brightness.dark;
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final row = {
        'userGuid': 'a',
        'teamno': 1,
        'teamName': 'Mi equipo',
        'ovRank': 1,
        'ovPoints': 310,
        'gdPoints': 40,
      };
      final snapshot = <String, dynamic>{
        'gameDay': 2,
        'leagues': {
          'leagues': [
            {'league_id': 'l', 'name': 'Liga', 'league_type': 'private'},
          ],
        },
        'leagueEvents': [
          {'gameDayId': 1, 'label': 'GP1'},
          {'gameDayId': 2, 'label': 'GP2'},
        ],
        'leaderboards': {
          'l': {
            'memRank': [row],
          },
        },
        'leagueHistory': {
          'l': {
            '1': {
              'memRank': [
                {...row, 'gdPoints': 30},
              ],
            },
            '2': {
              'memRank': [row],
            },
          },
        },
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fantasyAuthServiceProvider.overrideWithValue(_SavedAuth(snapshot)),
            myTeamProvider.overrideWith(_NoTeam.new),
            leagueWeekendAssetsProvider(2).overrideWith((ref) async => []),
            liveFantasyProvider.overrideWith(
              (ref) => Stream.value(
                LiveFantasySnapshot(
                  season: 2026,
                  round: 2,
                  meetingName: 'GP2',
                  sessionName: 'Carrera',
                  isLive: false,
                  isLocked: true,
                  updatedAt: DateTime(2026),
                  assets: const [],
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: LeagueScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cambiar color de Mi equipo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rojo neón'));
      await tester.pumpAndSettle();

      final selected = LeagueColors.palette[20].color;
      final textColor = LeagueColors.textColor(selected, Brightness.dark);
      expect(find.text('Mi equipo'), findsNWidgets(4));
      for (final text in tester.widgetList<Text>(find.text('Mi equipo'))) {
        expect(text.style!.color, textColor);
      }
      expect(tester.widget<Text>(find.text('#1')).style!.color, textColor);
      expect(
        tester.widget<Text>(find.text('Fin de semana: 40 pts')).style!.color,
        textColor,
      );
      final charts = tester
          .widgetList<LineChart>(find.byType(LineChart))
          .toList();
      expect(charts, hasLength(2));
      for (final chart in charts) {
        expect(chart.data.lineBarsData.single.color, selected);
      }
      expect(await LeagueColors.load('l'), {'a:1': 20});
      expect(tester.takeException(), isNull);
    },
  );
}
