import 'dart:convert';

class LeagueGpStanding {
  const LeagueGpStanding({
    required this.rank,
    required this.name,
    required this.points,
  });

  final int rank;
  final String name;
  final double points;
}

class LeagueLatestGp {
  const LeagueLatestGp({
    required this.leagueId,
    required this.leagueName,
    required this.round,
    required this.standings,
  });

  final String leagueId;
  final String leagueName;
  final int round;
  final List<LeagueGpStanding> standings;
}

class LeagueSnapshotReader {
  const LeagueSnapshotReader._();

  static LeagueLatestGp? latestGp(String raw, {String? selectedLeagueId}) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final snapshot = Map<String, dynamic>.from(decoded);
    final leagues = _extractList(snapshot['leagues'], const {
      'user_leagues',
      'leagues',
      'value',
      'results',
    }).where(_isSmallPrivateLeague).toList();
    if (leagues.isEmpty) return null;

    final selected = leagues.firstWhere(
      (league) => _leagueId(league) == selectedLeagueId,
      orElse: () => leagues.first,
    );
    final leagueId = _leagueId(selected);
    if (leagueId.isEmpty) return null;

    final allBoards = snapshot['leaderboards'];
    if (allBoards is! Map || allBoards[leagueId] is! Map) return null;
    final board = Map<String, dynamic>.from(allBoards[leagueId] as Map);
    final rawRounds = board['rounds'];
    if (rawRounds is! Map) return null;
    final rounds = rawRounds.keys
        .map((key) => int.tryParse(key.toString()))
        .whereType<int>()
        .toList()
      ..sort();
    if (rounds.isEmpty) return null;
    var latestRound = 0;
    var rows = const <Map<String, dynamic>>[];
    for (final round in rounds.reversed) {
      final candidate = _extractList(rawRounds[round.toString()], const {
        'leaderboard',
        'leaderboards',
        'value',
        'results',
      });
      if (candidate.isNotEmpty) {
        latestRound = round;
        rows = candidate;
        break;
      }
    }
    if (rows.isEmpty) return null;

    final standings = <LeagueGpStanding>[];
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final points = double.tryParse(
        (row['event_points'] ?? row['points'] ?? row['cur_points'] ?? '0')
            .toString(),
      );
      standings.add(
        LeagueGpStanding(
          rank: int.tryParse(
                (row['race_rank'] ??
                        row['rank'] ??
                        row['cur_rank'] ??
                        row['position'] ??
                        index + 1)
                    .toString(),
              ) ??
              index + 1,
          name: cleanFantasyName(
            _first(row, const ['team_name', 'user_name', 'name']) ??
                'Participante',
          ),
          points: points ?? 0,
        ),
      );
    }
    standings.sort((a, b) {
      final byRank = a.rank.compareTo(b.rank);
      return byRank != 0 ? byRank : b.points.compareTo(a.points);
    });
    return LeagueLatestGp(
      leagueId: leagueId,
      leagueName: cleanFantasyName(
        _first(selected, const ['league_name', 'leaguename', 'name']) ??
            'Liga privada',
      ),
      round: latestRound,
      standings: standings,
    );
  }

  static String _leagueId(Map<String, dynamic> league) =>
      (_first(league, const ['league_id', 'leagueid', 'id']) ?? '').toString();

  static bool _isSmallPrivateLeague(Map<String, dynamic> league) {
    final type =
        (_first(league, const ['league_type', 'leaguetype', 'type']) ?? '')
            .toString()
            .toLowerCase();
    final count = int.tryParse(
      (_first(league, const ['member_count', 'membercount', 'entry_count']) ??
              '')
          .toString(),
    );
    return (type.isEmpty || type.contains('private')) &&
        (count == null || count <= 20);
  }

  static List<Map<String, dynamic>> _extractList(
    dynamic node,
    Set<String> preferredKeys,
  ) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (preferredKeys.contains(entry.key.toString().toLowerCase()) &&
            entry.value is List) {
          final rows = (entry.value as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          if (rows.isNotEmpty) return rows;
        }
      }
      for (final value in node.values) {
        final rows = _extractList(value, preferredKeys);
        if (rows.isNotEmpty) return rows;
      }
    } else if (node is List) {
      final rows = node
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (rows.isNotEmpty) return rows;
    }
    return const [];
  }

  static dynamic _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      for (final entry in map.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase() &&
            entry.value != null) {
          return entry.value;
        }
      }
    }
    return null;
  }
}

String cleanFantasyName(Object value) {
  final raw = value.toString().trim();
  if (raw.isEmpty) return raw;
  try {
    return Uri.decodeComponent(raw.replaceAll('+', '%20'))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  } catch (_) {
    return raw.replaceAll('%20', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
