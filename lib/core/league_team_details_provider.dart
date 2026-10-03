import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Los puntos y el catálogo se consultan para el GP capturado, no para otro GP.
final leagueWeekendAssetsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, gameDay) {
      return ref.watch(fantasyApiProvider).getGameDayAssets(gameDay);
    });
