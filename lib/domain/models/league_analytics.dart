import 'league_access.dart';

class LeagueEvent {
  const LeagueEvent({
    required this.gameDayId,
    required this.label,
    this.isComplete = true,
  });

  final int gameDayId;
  final String label;
  final bool isComplete;
}

class LeagueMemberTrend {
  LeagueMemberTrend({required this.key, required this.name});

  final String key;
  String name;
  List<double?> eventPoints = const [];
  List<double?> cumulativePoints = const [];
  List<int?> positions = const [];
  int gold = 0;
  int silver = 0;
  int bronze = 0;
  int? currentRank;
  double? currentTotal;
  bool isCurrentUser = false;
}

class LeagueAnalytics {
  const LeagueAnalytics({
    required this.events,
    required this.members,
    this.identityAliases = const {},
  });

  /// Máximo de equipos que la app representa a la vez por liga.
  static const maxDisplayedTeams = LeagueAccess.maxTeams;

  final List<LeagueEvent> events;
  final List<LeagueMemberTrend> members;
  final Map<String, String> identityAliases;

  bool get hasHistory => events.length > 1;

  LeagueAnalytics get limitedForDisplay => members.length <= maxDisplayedTeams
      ? this
      : LeagueAnalytics(
          events: events,
          identityAliases: identityAliases,
          members: members.take(maxDisplayedTeams).toList(growable: false),
        );

  factory LeagueAnalytics.fromSnapshot(
    Map<String, dynamic> snapshot,
    String leagueId,
  ) {
    final accessRoot = snapshot['leagueAccess'];
    final boards = snapshot['leaderboards'];
    if (LeagueAccess.inspect(
      league: const {},
      board: boards is Map ? boards[leagueId] : null,
      capturedAccess: accessRoot is Map && accessRoot[leagueId] is Map
          ? accessRoot[leagueId] as Map
          : null,
    ).isBlocked) {
      return const LeagueAnalytics(events: [], members: []);
    }
    final historyRoot = snapshot['leagueHistory'];
    final history = historyRoot is Map && historyRoot[leagueId] is Map
        ? Map<dynamic, dynamic>.from(historyRoot[leagueId] as Map)
        : <dynamic, dynamic>{};
    final currentRoot = snapshot['leaderboards'];
    final rawCurrent = currentRoot is Map ? currentRoot[leagueId] : null;
    // También acepta las capturas Polewise anteriores, con current/rounds.
    final current = rawCurrent is Map && rawCurrent['current'] != null
        ? rawCurrent['current']
        : rawCurrent;
    if (history.isEmpty && rawCurrent is Map && rawCurrent['rounds'] is Map) {
      history.addAll(Map<dynamic, dynamic>.from(rawCurrent['rounds'] as Map));
    }

    final eventLabels = <int, String>{};
    final eventCompletion = <int, bool>{};
    final rawEvents = snapshot['leagueEvents'];
    if (rawEvents is List) {
      for (final raw in rawEvents.whereType<Map>()) {
        final day = _asInt(
          _first(raw, const ['gamedayid', 'gameDayId', 'day']),
        );
        if (day == null) continue;
        eventLabels[day] = _decode(
          (_first(raw, const ['label', 'name']) ?? 'R$day').toString(),
        );
        eventCompletion[day] =
            _asBool(
              _first(raw, const ['iscomplete', 'isComplete', 'complete']),
            ) ??
            true;
      }
    }

    final eventBoards = <int, List<Map<String, dynamic>>>{};
    for (final entry in history.entries) {
      final day = int.tryParse(entry.key.toString());
      if (day == null) continue;
      if (LeagueAccess.inspect(
        league: const {},
        board: entry.value,
      ).isBlocked) {
        continue;
      }
      final rows = extractLeagueRows(entry.value);
      if (rows.isNotEmpty) eventBoards[day] = rows;
    }
    if (eventBoards.isEmpty) {
      final rows = extractLeagueRows(current);
      if (rows.isNotEmpty) {
        final day = _asInt(snapshot['gameDay']) ?? 0;
        eventBoards[day] = rows;
        eventLabels[day] = 'Actual';
      }
    }

    final days = eventBoards.keys.toList()..sort();
    final events = days
        .map(
          (day) => LeagueEvent(
            gameDayId: day,
            label: eventLabels[day] ?? 'R$day',
            isComplete: eventCompletion[day] ?? true,
          ),
        )
        .toList();
    final currentRows = extractLeagueRows(current);
    final identities = _LeagueIdentities([
      ...currentRows,
      for (final rows in eventBoards.values) ...rows,
    ]);
    final currentKeys = currentRows
        .map((row) => identities.of(row).key)
        .toSet();
    final builders = <String, _MemberBuilder>{};

    for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
      for (final row in eventBoards[events[eventIndex].gameDayId] ?? const []) {
        if (_asBool(_first(row, const ['_has_event'])) == false) continue;
        final identity = identities.of(row);
        final builder = builders.putIfAbsent(
          identity.key,
          () => _MemberBuilder(identity.key, identity.name, events.length),
        );
        builder.name = identity.name;
        builder.isCurrentUser = builder.isCurrentUser || _isCurrentUser(row);
        builder.eventPoints[eventIndex] = _asDouble(
          _first(row, const [
            'gdpoints',
            'gamedaypoints',
            'gameday_points',
            'matchdaypoints',
            'racepoints',
            'eventpoints',
            'event_points',
            'weekpoints',
            'cur_points',
          ]),
        );
        builder.eventRanks[eventIndex] = _asInt(
          _first(row, const [
            'gdrank',
            'eventrank',
            'race_rank',
            'cur_rank',
            'rank',
            'position',
          ]),
        );
        builder.reportedTotals[eventIndex] = _asDouble(
          _first(row, const [
            'ovpoints',
            'overallpoints',
            'overall_points',
            'totalpoints',
            'total_points',
            'cumulative_points',
            'points',
            'score',
          ]),
        );
      }
    }

    for (final row in currentRows) {
      final identity = identities.of(row);
      final builder = builders.putIfAbsent(
        identity.key,
        () => _MemberBuilder(identity.key, identity.name, events.length),
      );
      builder.name = identity.name;
      builder.isCurrentUser = builder.isCurrentUser || _isCurrentUser(row);
      builder.currentRank = _asInt(
        _first(row, const [
          'ovrank',
          'gdrank',
          'cur_rank',
          'userrank',
          'rank',
          'position',
          'overall_rank',
        ]),
      );
      builder.currentTotal = _asDouble(
        _first(row, const [
          'ovpoints',
          'overallpoints',
          'overall_points',
          'totalpoints',
          'total_points',
          'points',
          'cur_points',
          'score',
        ]),
      );
    }

    // La clasificación actual determina quién sigue en la liga. No contamos
    // alias históricos ni antiguos miembros como equipos adicionales.
    if (currentKeys.isNotEmpty) {
      builders.removeWhere((key, _) => !currentKeys.contains(key));
    }
    for (final builder in builders.values) {
      double running = 0;
      double? previousReportedTotal;
      for (var i = 0; i < events.length; i++) {
        var points = builder.eventPoints[i];
        final reportedTotal = builder.reportedTotals[i];
        if (points == null && reportedTotal != null) {
          points = previousReportedTotal == null
              ? reportedTotal
              : reportedTotal - previousReportedTotal;
        }
        if (reportedTotal != null) previousReportedTotal = reportedTotal;
        builder.eventPoints[i] = points;
        if (points != null) {
          running += points;
          builder.cumulativePoints[i] = running;
        }
      }
    }

    for (var i = 0; i < events.length; i++) {
      final cumulativeRanking =
          builders.values
              .where((member) => member.cumulativePoints[i] != null)
              .toList()
            ..sort(
              (a, b) =>
                  b.cumulativePoints[i]!.compareTo(a.cumulativePoints[i]!),
            );
      for (var rank = 0; rank < cumulativeRanking.length; rank++) {
        cumulativeRanking[rank].positions[i] = rank + 1;
      }

      if (!events[i].isComplete) continue;
      final eventRanking =
          builders.values
              .where((member) => member.eventPoints[i] != null)
              .toList()
            ..sort((a, b) => b.eventPoints[i]!.compareTo(a.eventPoints[i]!));
      var computedRank = 1;
      double? previousPoints;
      for (var index = 0; index < eventRanking.length; index++) {
        final points = eventRanking[index].eventPoints[i]!;
        if (previousPoints != null && points != previousPoints) {
          computedRank = index + 1;
        }
        previousPoints = points;
        final reportedRank = eventRanking[index].eventRanks[i];
        switch (reportedRank ?? computedRank) {
          case 1:
            eventRanking[index].gold++;
          case 2:
            eventRanking[index].silver++;
          case 3:
            eventRanking[index].bronze++;
        }
      }
    }

    final members = builders.values.map((builder) => builder.build()).toList()
      ..sort((a, b) {
        if (a.currentRank != null || b.currentRank != null) {
          return (a.currentRank ?? 999).compareTo(b.currentRank ?? 999);
        }
        return (b.currentTotal ?? 0).compareTo(a.currentTotal ?? 0);
      });
    return LeagueAnalytics(
      events: events,
      members: members,
      identityAliases: identities.aliasKeys,
    );
  }
}

class _MemberBuilder {
  _MemberBuilder(this.key, this.name, int eventCount)
    : eventPoints = List<double?>.filled(eventCount, null),
      eventRanks = List<int?>.filled(eventCount, null),
      reportedTotals = List<double?>.filled(eventCount, null),
      cumulativePoints = List<double?>.filled(eventCount, null),
      positions = List<int?>.filled(eventCount, null);

  final String key;
  String name;
  final List<double?> eventPoints;
  final List<int?> eventRanks;
  final List<double?> reportedTotals;
  final List<double?> cumulativePoints;
  final List<int?> positions;
  int gold = 0;
  int silver = 0;
  int bronze = 0;
  int? currentRank;
  double? currentTotal;
  bool isCurrentUser = false;

  LeagueMemberTrend build() => LeagueMemberTrend(key: key, name: name)
    ..eventPoints = List.unmodifiable(eventPoints)
    ..cumulativePoints = List.unmodifiable(cumulativePoints)
    ..positions = List.unmodifiable(positions)
    ..gold = gold
    ..silver = silver
    ..bronze = bronze
    ..currentRank = currentRank
    ..currentTotal = currentTotal
    ..isCurrentUser = isCurrentUser;
}

bool _isCurrentUser(Map<String, dynamic> row) =>
    _asBool(
      _first(row, const [
        'isloggedinuser',
        'is_logged_in_user',
        'iscurrentuser',
        'is_current_user',
        'isme',
        'is_me',
      ]),
    ) ??
    false;

({String key, String name, String? owner, String? teamNo}) _identity(
  Map<String, dynamic> row,
) {
  final rawName =
      _first(row, const [
        'teamname',
        'team_name',
        'entry_name',
        'display_name',
        'username',
        'user_name',
        'name',
      ]) ??
      'Participante';
  final name = _displayValue(rawName);
  final rawId = _first(row, const [
    'yuserguid',
    'userguid',
    'user_guid',
    'userid',
    'user_id',
    'guid',
    'socialid',
    'social_id',
    'teamid',
    'team_id',
    'entryid',
    'entry_id',
  ]);
  final key = rawId?.toString().trim().isNotEmpty == true
      ? rawId.toString().trim()
      : name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final rawTeamNo = _first(row, const ['teamno', 'team_no', 'teamnumber']);
  final teamNo = _asInt(rawTeamNo)?.toString();
  return (
    key: teamNo == null ? key : '$key:$teamNo',
    name: name,
    owner: rawId?.toString().trim(),
    teamNo: teamNo,
  );
}

class _LeagueIdentities {
  _LeagueIdentities(this.rows) {
    for (final row in rows) {
      final guid = _first(row, const [
        'yuserguid',
        'userguid',
        'user_guid',
        'guid',
      ]);
      if (guid == null) continue;
      final owner = guid.toString().trim();
      for (final field in const [
        'yuserguid',
        'userguid',
        'user_guid',
        'guid',
        'userid',
        'user_id',
        'socialid',
        'social_id',
      ]) {
        final alias = _first(row, [field]);
        if (alias != null) {
          aliases
              .putIfAbsent(alias.toString().trim(), () => <String>{})
              .add(owner);
        }
      }
    }
  }

  final List<Map<String, dynamic>> rows;
  final aliases = <String, Set<String>>{};

  ({String key, String name, String? owner, String? teamNo}) _canonical(
    Map<String, dynamic> row,
  ) {
    final identity = _identity(row);
    final owners = aliases[identity.owner];
    final owner = owners?.length == 1 ? owners!.single : identity.owner;
    return (
      key: owner == null
          ? identity.key
          : identity.teamNo == null
          ? owner
          : '$owner:${identity.teamNo}',
      name: identity.name,
      owner: owner,
      teamNo: identity.teamNo,
    );
  }

  ({String key, String name}) of(Map<String, dynamic> row) {
    final identity = _canonical(row);
    if (identity.teamNo != null) {
      return (key: identity.key, name: identity.name);
    }
    final sameOwner = rows
        .map(_canonical)
        .where(
          (candidate) =>
              identity.owner != null &&
              candidate.owner == identity.owner &&
              candidate.teamNo != null,
        )
        .toList();
    final sameName = sameOwner
        .where(
          (candidate) =>
              _normalizedName(candidate.name) == _normalizedName(identity.name),
        )
        .toList();
    final matches = sameName.isNotEmpty ? sameName : sameOwner;
    final keys = matches.map((candidate) => candidate.key).toSet();
    if (keys.length == 1) return (key: keys.single, name: identity.name);
    // Una fila sin número de equipo no se atribuye a uno de varios equipos
    // del mismo dueño por posición ni por azar.
    return (key: identity.key, name: identity.name);
  }

  Map<String, String> get aliasKeys {
    final targets = <String, Set<String>>{};
    for (final row in rows) {
      final identity = _identity(row);
      final canonical = of(row).key;
      final keys = <String>{identity.key};
      for (final field in const [
        'social_id',
        'socialid',
        'user_id',
        'userid',
        'user_guid',
        'userguid',
        'yuserguid',
        'guid',
      ]) {
        final raw = _first(row, [field]);
        if (raw != null) {
          final owner = raw.toString().trim();
          keys.add(owner);
          if (identity.teamNo != null) keys.add('$owner:${identity.teamNo}');
        }
      }
      for (final alias in keys) {
        targets.putIfAbsent(alias, () => <String>{}).add(canonical);
      }
    }
    return {
      for (final entry in targets.entries)
        if (entry.value.length == 1) entry.key: entry.value.single,
    };
  }

  String _normalizedName(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<Map<String, dynamic>> extractLeagueRows(dynamic node) {
  const preferred = {
    'leaderboards',
    'leaderboard',
    'entries',
    'results',
    'member',
    'details',
    'value',
  };
  if (node is Map) {
    final rankedRows = <Map<String, dynamic>>[];
    for (final preferredKey in const ['userrank', 'memrank']) {
      for (final entry in node.entries) {
        if (entry.key.toString().toLowerCase() != preferredKey ||
            entry.value is! List) {
          continue;
        }
        rankedRows.addAll(
          (entry.value as List).whereType<Map>().map(
            (row) => Map<String, dynamic>.from(row),
          ),
        );
      }
    }
    if (rankedRows.isNotEmpty) return rankedRows;
    for (final entry in node.entries) {
      if (preferred.contains(entry.key.toString().toLowerCase()) &&
          entry.value is List) {
        final rows = (entry.value as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        if (rows.isNotEmpty) return rows;
      }
    }
    for (final value in node.values) {
      final rows = extractLeagueRows(value);
      if (rows.isNotEmpty) return rows;
    }
  } else if (node is List) {
    final rows = node
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (rows.isNotEmpty) return rows;
  }
  return const [];
}

dynamic _first(Map map, List<String> keys) {
  // La prioridad de identificadores debe ser estable, no depender del orden
  // de campos del JSON (social_id y user_guid no son intercambiables).
  for (final key in keys) {
    for (final entry in map.entries) {
      if (entry.key.toString().toLowerCase() != key.toLowerCase()) continue;
      final value = entry.value;
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value == 1 || value == '1' || value == 'true') return true;
  if (value == 0 || value == '0' || value == 'false') return false;
  return null;
}

String _displayValue(dynamic value) {
  if (value is List) {
    final parts = value
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => _decode(item.toString()))
        .toList();
    return parts.isEmpty ? 'Participante' : parts.join(' / ');
  }
  return _decode(value.toString());
}

String _decode(String value) {
  try {
    return Uri.decodeComponent(value.replaceAll('+', ' '));
  } catch (_) {
    return value;
  }
}
