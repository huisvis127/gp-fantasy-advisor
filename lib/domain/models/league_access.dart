/// Limits apply before building analytics or requesting history and line-ups.
class LeagueAccess {
  const LeagueAccess(this.teamCount);

  static const maxTeams = 20;
  final int? teamCount;
  bool get isBlocked => teamCount != null && teamCount! > maxTeams;

  static const _countFields = {
    'teamcount',
    'totalteams',
    'numberofteams',
    'noofteams',
    'membercount',
    'memcount',
    'totalmembers',
    'numberofmembers',
    'noofmembers',
    'participantcount',
    'totalparticipants',
    'entrycount',
    'totalentries',
    'totalrecords',
    'totalrecord',
  };

  static int? _reportedCount(Map<dynamic, dynamic>? data) {
    if (data == null) return null;
    int? largest;
    for (final entry in data.entries) {
      final key = entry.key.toString().toLowerCase().replaceAll('_', '');
      if (!_countFields.contains(key)) continue;
      final count = int.tryParse(entry.value?.toString() ?? '');
      if (count != null && count >= 0 && (largest == null || count > largest)) {
        largest = count;
      }
    }
    for (final child in data.values.whereType<Map>()) {
      final count = _reportedCount(child);
      if (count != null && (largest == null || count > largest)) {
        largest = count;
      }
    }
    return largest;
  }

  static LeagueAccess inspect({
    required Map<dynamic, dynamic> league,
    dynamic board,
    Map<dynamic, dynamic>? capturedAccess,
  }) {
    var count = _reportedCount(league);
    final capturedCount = _reportedCount(capturedAccess);
    if (capturedCount != null && (count == null || capturedCount > count)) {
      count = capturedCount;
    }
    if (count != null && count > maxTeams) return LeagueAccess(count);
    if (board is Map && board['current'] != null) board = board['current'];
    final boardCount = _reportedCount(board is Map ? board : null);
    if (boardCount != null && (count == null || boardCount > count)) {
      count = boardCount;
    }
    if (count != null && count > maxTeams) return LeagueAccess(count);
    final keys = <String>{};
    for (final row in _rows(board)) {
      final values = {
        for (final entry in row.entries)
          entry.key.toString().toLowerCase().replaceAll('_', ''): entry.value,
      };
      final owner =
          values['yuserguid'] ??
          values['userguid'] ??
          values['guid'] ??
          values['userid'] ??
          values['socialid'];
      final team = values['teamno'] ?? values['teamnumber'] ?? 1;
      // Distinct teams count once even if repeated in memRank/userRank.
      final key = owner == null ? 'row:${keys.length}' : '$owner:$team';
      keys.add(key);
      if (keys.length > maxTeams) {
        return LeagueAccess(
          count != null && count > keys.length ? count : keys.length,
        );
      }
    }
    if (keys.isNotEmpty && (count == null || keys.length > count)) {
      count = keys.length;
    }
    return LeagueAccess(count);
  }

  static Iterable<Map> _rows(dynamic node) sync* {
    if (node is List) {
      yield* node.whereType<Map>();
    } else if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString().toLowerCase();
        if ({
              'userrank',
              'memrank',
              'leaderboard',
              'entries',
              'members',
              'results',
              'details',
              'member',
            }.contains(key) &&
            entry.value is List) {
          yield* (entry.value as List).whereType<Map>();
        }
      }
      for (final value in node.values.whereType<Map>()) {
        yield* _rows(value);
      }
    }
  }
}
