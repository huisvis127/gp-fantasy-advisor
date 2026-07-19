/// Modelo tolerante de las respuestas no documentadas de F1 Fantasy.
///
/// La API ha usado distintos nombres para las mismas colecciones según la
/// temporada. Centralizar esa compatibilidad evita que la pantalla descarte
/// participantes (por ejemplo, cuando llegan bajo `standings` y no `entries`).
class FantasyLeague {
  const FantasyLeague({
    required this.id,
    required this.name,
    required this.memberCount,
  });

  final String id;
  final String name;
  final int? memberCount;

  static List<FantasyLeague> fromEntrantsResponse(Map<String, dynamic> raw) {
    final items = _findList(raw, const ['leagues', 'league_entrants', 'items']);
    return items
        .map(_fromJson)
        .where((league) => league.id.isNotEmpty)
        .toList();
  }

  static FantasyLeague _fromJson(dynamic value) {
    final json = _asMap(value);
    return FantasyLeague(
      id: _first(json, const ['league_id', 'leagueId', 'id']).toString(),
      name:
          _first(json, const [
            'league_name',
            'leagueName',
            'name',
          ]).toString().trim().isEmpty
          ? 'Liga'
          : _first(json, const [
              'league_name',
              'leagueName',
              'name',
            ]).toString(),
      memberCount: _asInt(
        _first(json, const [
          'entry_count',
          'entryCount',
          'members_count',
          'memberCount',
        ]),
      ),
    );
  }
}

class FantasyLeagueEntry {
  const FantasyLeagueEntry({
    required this.id,
    required this.managerName,
    required this.teamName,
    required this.rank,
    required this.points,
    this.teamValue,
    this.members = const <FantasyLeagueMember>[],
    this.chipsUsed = const <String>{},
    this.positionHistory = const <LeaguePosition>[],
  });

  final String id;
  final String managerName;
  final String teamName;
  final int? rank;
  final double points;
  final double? teamValue;
  final List<FantasyLeagueMember> members;
  final Set<String> chipsUsed;
  final List<LeaguePosition> positionHistory;

  static List<FantasyLeagueEntry> fromLeaderboardResponse(
    Map<String, dynamic> raw,
  ) {
    final items = _findList(raw, const [
      'standings',
      'entries',
      'leaderboard',
      'league_entries',
      'results',
    ]);
    final seen = <String>{};
    final entries = <FantasyLeagueEntry>[];
    for (final item in items) {
      final entry = _fromJson(item);
      // El identificador puede faltar: en ese caso la combinación visible es
      // suficiente para no borrar un equipo legítimo de la clasificación.
      final key = entry.id.isEmpty
          ? '${entry.managerName}|${entry.teamName}'
          : entry.id;
      if (seen.add(key)) entries.add(entry);
    }
    entries.sort((a, b) {
      final byRank = (a.rank ?? 1 << 30).compareTo(b.rank ?? 1 << 30);
      return byRank != 0 ? byRank : b.points.compareTo(a.points);
    });
    return entries;
  }

  static FantasyLeagueEntry _fromJson(dynamic value) {
    final json = _asMap(value);
    final team = _asMap(_first(json, const ['team', 'entry', 'fantasy_team']));
    final manager = _asMap(_first(json, const ['manager', 'user', 'owner']));
    final managerName = _first(json, const [
      'manager_name',
      'managerName',
      'player_name',
      'playerName',
      'name',
    ]);
    final teamName = _first(json, const [
      'team_name',
      'teamName',
      'entry_name',
      'entryName',
    ]);
    final memberItems = _findListInMaps(
      [json, team],
      const [
        'players',
        'picks',
        'assets',
        'lineup',
        'team_players',
        'teamPlayers',
      ],
    );
    final historyItems = _findListInMaps(
      [json, team],
      const [
        'rank_history',
        'rankHistory',
        'position_history',
        'positionHistory',
        'history',
        'rounds',
        'race_results',
        'raceResults',
      ],
    );
    return FantasyLeagueEntry(
      id: _first(json, const [
        'entry_id',
        'entryId',
        'team_id',
        'teamId',
        'id',
      ]).toString(),
      managerName:
          (managerName.toString().trim().isNotEmpty
                  ? managerName
                  : _first(manager, const [
                      'name',
                      'display_name',
                      'displayName',
                    ]))
              .toString()
              .trim(),
      teamName:
          (teamName.toString().trim().isNotEmpty
                  ? teamName
                  : _first(team, const ['name', 'team_name', 'teamName']))
              .toString()
              .trim(),
      rank: _asInt(
        _first(json, const ['rank', 'position', 'overall_rank', 'overallRank']),
      ),
      points:
          _asDouble(
            _first(json, const [
              'points',
              'total_points',
              'totalPoints',
              'score',
            ]),
          ) ??
          0,
      teamValue: _asDouble(
        _first(json, const ['team_value', 'teamValue', 'value']),
      ),
      members: memberItems
          .map(FantasyLeagueMember.fromJson)
          .where((member) => member.name.isNotEmpty)
          .toList(),
      chipsUsed: _parseChips(json, team),
      positionHistory: _parseHistory(historyItems),
    );
  }
}

class FantasyLeagueMember {
  const FantasyLeagueMember({
    required this.id,
    required this.name,
    required this.isConstructor,
  });

  final String id;
  final String name;
  final bool isConstructor;

  factory FantasyLeagueMember.fromJson(dynamic value) {
    final json = _asMap(value);
    final player = _asMap(
      _first(json, const ['player', 'asset', 'driver', 'constructor']),
    );
    final source = player.isEmpty ? json : player;
    final rawName = _first(source, const [
      'display_name',
      'displayName',
      'full_name',
      'fullName',
      'name',
      'driver_name',
      'driverName',
      'team_name',
      'teamName',
      'abbreviation',
    ]).toString().trim();
    final type = _first(source, const [
      'position',
      'type',
      'asset_type',
      'assetType',
    ]).toString().toLowerCase();
    return FantasyLeagueMember(
      id: _first(source, const [
        'id',
        'player_id',
        'playerId',
        'asset_id',
        'assetId',
      ]).toString(),
      name: rawName,
      isConstructor:
          source['is_constructor'] == true ||
          source['isConstructor'] == true ||
          type.contains('constructor') ||
          type == 'cn',
    );
  }
}

class LeaguePosition {
  const LeaguePosition({
    required this.round,
    required this.label,
    required this.rank,
  });

  final int round;
  final String label;
  final int rank;
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

dynamic _first(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return '';
}

List<dynamic> _findList(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is List) return value;
    if (value is Map) {
      final nested = _findList(Map<String, dynamic>.from(value), keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  final data = raw['data'];
  return data is Map
      ? _findList(Map<String, dynamic>.from(data), keys)
      : const [];
}

List<dynamic> _findListInMaps(
  List<Map<String, dynamic>> maps,
  List<String> keys,
) {
  for (final map in maps) {
    final found = _findList(map, keys);
    if (found.isNotEmpty) return found;
  }
  return const [];
}

Set<String> _parseChips(Map<String, dynamic> json, Map<String, dynamic> team) {
  final values = <dynamic>[];
  for (final source in [json, team]) {
    for (final key in const [
      'chips_used',
      'chipsUsed',
      'used_chips',
      'usedChips',
      'boosters_used',
      'boostersUsed',
      'chips',
      'boosters',
    ]) {
      final value = source[key];
      if (value is List) values.addAll(value);
      if (value is Map) {
        value.forEach((name, used) {
          if (used == true ||
              used is num && used > 0 ||
              used is String && used.isNotEmpty) {
            values.add(name);
          }
        });
      }
      if (value is String) values.addAll(value.split(','));
    }
  }
  return values
      .map((value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          return _first(map, const [
            'name',
            'chip',
            'booster',
            'type',
            'slug',
          ]).toString();
        }
        return value.toString();
      })
      .map(_normaliseChip)
      .where((name) => name.isNotEmpty)
      .toSet();
}

String _normaliseChip(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

List<LeaguePosition> _parseHistory(List<dynamic> items) {
  final result = <LeaguePosition>[];
  for (var i = 0; i < items.length; i++) {
    final value = items[i];
    if (value is num) {
      result.add(
        LeaguePosition(round: i + 1, label: 'R${i + 1}', rank: value.toInt()),
      );
      continue;
    }
    final json = _asMap(value);
    final rank = _asInt(
      _first(json, const ['rank', 'position', 'league_rank', 'leagueRank']),
    );
    if (rank == null || rank < 1) continue;
    final round =
        _asInt(
          _first(json, const [
            'round',
            'gameweek',
            'race_number',
            'raceNumber',
          ]),
        ) ??
        i + 1;
    final rawLabel = _first(json, const [
      'short_name',
      'shortName',
      'race_name',
      'raceName',
      'label',
      'name',
    ]).toString().trim();
    result.add(
      LeaguePosition(
        round: round,
        label: rawLabel.isEmpty ? 'R$round' : rawLabel,
        rank: rank,
      ),
    );
  }
  result.sort((a, b) => a.round.compareTo(b.round));
  return result;
}

int? _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value.toString());
double? _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value.toString());
