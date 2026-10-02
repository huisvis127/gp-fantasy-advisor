import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final leagueCurrentBoardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, leagueId) {
      return ref.watch(fantasyApiProvider).getPrivateLeagueStandings(leagueId);
    });
