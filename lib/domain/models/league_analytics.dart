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
}

class LeagueAnalytics {
  const LeagueAnalytics({required this.events, required this.members});

  final List<LeagueEvent> events;
  final List<LeagueMemberTrend> members;

  bool get hasHistory => events.length > 1;

  factory LeagueAnalytics.fromSnapshot(
    Map<String, dynamic> snapshot,
    String leagueId,
  ) {
    final historyRoot = snapshot['leagueHistory'];
    final history = historyRoot is Map && historyRoot[leagueId] is Map
        ? Map<dynamic, dynamic>.from(historyRoot[leagueId] as Map)
        : <dynamic, dynamic>{};
    final currentRoot = snapshot['leaderboards'];
    final current = currentRoot is Map ? currentRoot[leagueId] : null;

    final eventLabels = <int, String>{};
    final eventCompletion = <int, bool>{};
    final rawEvents = snapshot['leagueEvents'];
    if (rawEvents is List) {
      for (final raw in rawEvents.whereType<Map>()) {
        final day =
            _asInt(_first(raw, const ['gamedayid', 'gameDayId', 'day']));
        if (day == null) continue;
        eventLabels[day] = _decode(
          (_first(raw, const ['label', 'name']) ?? 'R$day').toString(),
        );
        eventCompletion[day] = _asBool(_first(
              raw,
              const ['iscomplete', 'isComplete', 'complete'],
            )) ??
            true;
      }
    }

    final eventBoards = <int, List<Map<String, dynamic>>>{};
    for (final entry in history.entries) {
      final day = int.tryParse(entry.key.toString());
      if (day == null) continue;
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
        .map((day) => LeagueEvent(
              gameDayId: day,
              label: eventLabels[day] ?? 'R$day',
              isComplete: eventCompletion[day] ?? true,
            ))
        .toList();
    final builders = <String, _MemberBuilder>{};

    for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
      for (final row in eventBoards[events[eventIndex].gameDayId] ?? const []) {
        final identity = _identity(row);
        final builder = builders.putIfAbsent(
          identity.key,
          () => _MemberBuilder(identity.key, identity.name, events.length),
        );
        builder.name = identity.name;
        builder.eventPoints[eventIndex] = _asDouble(_first(row, const [
          'gamedaypoints',
          'gameday_points',
          'matchdaypoints',
          'racepoints',
          'eventpoints',
          'weekpoints',
        ]));
        builder.reportedTotals[eventIndex] = _asDouble(_first(row, const [
          'ovpoints',
          'overallpoints',
          'overall_points',
          'totalpoints',
          'total_points',
          'points',
          'score',
        ]));
      }
    }

    for (final row in extractLeagueRows(current)) {
      final identity = _identity(row);
      final builder = builders.putIfAbsent(
        identity.key,
        () => _MemberBuilder(identity.key, identity.name, events.length),
      );
      builder.name = identity.name;
      builder.currentRank = _asInt(_first(
        row,
        const ['userrank', 'rank', 'position', 'overall_rank'],
      ));
      builder.currentTotal = _asDouble(_first(row, const [
        'ovpoints',
        'overallpoints',
        'overall_points',
        'totalpoints',
        'total_points',
        'points',
        'score',
      ]));
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
      final cumulativeRanking = builders.values
          .where((member) => member.cumulativePoints[i] != null)
          .toList()
        ..sort(
            (a, b) => b.cumulativePoints[i]!.compareTo(a.cumulativePoints[i]!));
      for (var rank = 0; rank < cumulativeRanking.length; rank++) {
        cumulativeRanking[rank].positions[i] = rank + 1;
      }

      if (!events[i].isComplete) continue;
      final eventRanking = builders.values
          .where((member) => member.eventPoints[i] != null)
          .toList()
        ..sort((a, b) => b.eventPoints[i]!.compareTo(a.eventPoints[i]!));
      if (eventRanking.isNotEmpty) eventRanking[0].gold++;
      if (eventRanking.length > 1) eventRanking[1].silver++;
      if (eventRanking.length > 2) eventRanking[2].bronze++;
    }

    final members = builders.values.map((builder) => builder.build()).toList()
      ..sort((a, b) {
        if (a.currentRank != null || b.currentRank != null) {
          return (a.currentRank ?? 999).compareTo(b.currentRank ?? 999);
        }
        return (b.currentTotal ?? 0).compareTo(a.currentTotal ?? 0);
      });
    return LeagueAnalytics(events: events, members: members);
  }
}

class _MemberBuilder {
  _MemberBuilder(this.key, this.name, int eventCount)
      : eventPoints = List<double?>.filled(eventCount, null),
        reportedTotals = List<double?>.filled(eventCount, null),
        cumulativePoints = List<double?>.filled(eventCount, null),
        positions = List<int?>.filled(eventCount, null);

  final String key;
  String name;
  final List<double?> eventPoints;
  final List<double?> reportedTotals;
  final List<double?> cumulativePoints;
  final List<int?> positions;
  int gold = 0;
  int silver = 0;
  int bronze = 0;
  int? currentRank;
  double? currentTotal;

  LeagueMemberTrend build() => LeagueMemberTrend(key: key, name: name)
    ..eventPoints = List.unmodifiable(eventPoints)
    ..cumulativePoints = List.unmodifiable(cumulativePoints)
    ..positions = List.unmodifiable(positions)
    ..gold = gold
    ..silver = silver
    ..bronze = bronze
    ..currentRank = currentRank
    ..currentTotal = currentTotal;
}

({String key, String name}) _identity(Map<String, dynamic> row) {
  final rawName = _first(row, const [
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
    'userguid',
    'userid',
    'user_id',
    'guid',
    'teamid',
    'team_id',
    'entryid',
    'entry_id',
  ]);
  final key = rawId?.toString().trim().isNotEmpty == true
      ? rawId.toString()
      : name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return (key: key, name: name);
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
  final wanted = keys.map((key) => key.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (!wanted.contains(entry.key.toString().toLowerCase())) continue;
    final value = entry.value;
    if (value != null && value.toString().trim().isNotEmpty) return value;
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
