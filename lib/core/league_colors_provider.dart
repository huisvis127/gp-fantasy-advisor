import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'league_colors.dart';

final leagueTeamColorsProvider =
    StateNotifierProvider.family<
      LeagueTeamColorsController,
      Map<String, int>,
      String
    >((ref, leagueId) => LeagueTeamColorsController(leagueId));

/// Una sola selección reactiva para todas las vistas del mismo equipo.
class LeagueTeamColorsController extends StateNotifier<Map<String, int>> {
  LeagueTeamColorsController(this.leagueId) : super(const {}) {
    _load();
  }

  final String leagueId;
  Future<void> _writes = Future.value();

  Future<void> _load() async {
    final saved = await LeagueColors.load(leagueId);
    if (mounted) state = Map.unmodifiable({...saved, ...state});
  }

  Future<void> select(String memberKey, int index) {
    state = Map.unmodifiable({
      ...state,
      memberKey: index.clamp(0, LeagueColors.palette.length - 1),
    });
    final write = _writes.then(
      (_) => LeagueColors.save(leagueId, memberKey, index),
    );
    _writes = write.catchError((Object error) {});
    return write;
  }
}
