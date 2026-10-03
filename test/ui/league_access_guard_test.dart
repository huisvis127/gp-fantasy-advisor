import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gp_fantasy_advisor/core/league_current_board_provider.dart';
import 'package:gp_fantasy_advisor/core/league_team_details_provider.dart';
import 'package:gp_fantasy_advisor/core/providers.dart';
import 'package:gp_fantasy_advisor/core/theme.dart';
import 'package:gp_fantasy_advisor/data/sources/fantasy_auth_service.dart';
import 'package:gp_fantasy_advisor/ui/screens/league/league_screen.dart';
import 'package:gp_fantasy_advisor/ui/widgets/league_team_weekend_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends FantasyAuthService {
  _Auth(this.snapshot) : super(Dio(), loginBaseUrl: 'https://example.test');
  final Map<String, dynamic> snapshot;
  @override
  Future<String?> readStoredToken() async => null;
  @override
  Future<String?> readSessionSnapshot() async => jsonEncode(snapshot);
}

void main() {
  for (final known in [true, false]) {
    testWidgets(
      'blocks a large league ${known ? 'before requests' : 'after size check'}',
      (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        SharedPreferences.setMockInitialValues({});
        var boardRequests = 0;
        var assetRequests = 0;
        final snapshot = <String, dynamic>{
          'gameDay': 2,
          'leagues': {
            'leagues': [
              {
                'league_id': 'large',
                'name': 'Liga grande',
                'league_type': 'private',
                if (known) 'TotalMembers': 10000,
              },
            ],
          },
          // This history must never be processed for an ineligible league.
          'leagueHistory': {
            'large': {
              '1': {
                'memRank': [
                  for (var i = 0; i < 1000; i++)
                    {'userGuid': 'u$i', 'teamName': 'Equipo $i'},
                ],
              },
            },
          },
        };
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              fantasyAuthServiceProvider.overrideWithValue(_Auth(snapshot)),
              leagueCurrentBoardProvider('large').overrideWith((ref) async {
                boardRequests++;
                return {
                  'Value': {
                    'leaderboard': [
                      for (var i = 0; i < 21; i++)
                        {'user_guid': 'u$i', 'team_no': 1},
                    ],
                  },
                };
              }),
              leagueWeekendAssetsProvider(2).overrideWith((ref) async {
                assetRequests++;
                return [];
              }),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: const Scaffold(body: LeagueScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(boardRequests, known ? 0 : 1);
        expect(assetRequests, 0);
        expect(find.text('Límite de equipos'), findsOneWidget);
        expect(find.byType(LeagueTeamWeekendDetails), findsNothing);
        expect(find.text('ACTUALIZAR LIGAS E HISTORIAL'), findsNothing);
        final selector = tester.widget<DropdownButton<String>>(
          find.byType(DropdownButton<String>),
        );
        expect(selector.items!.single.enabled, false);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
