import 'league_analytics.dart';

/// Una puntuación de una sesión que forma parte de una jornada.
class LeagueTeamSessionPoints {
  const LeagueTeamSessionPoints({required this.name, required this.points});

  final String name;
  final double? points;
}

/// Un piloto o constructor elegido por un miembro de una liga.
class LeagueTeamAssetDetails {
  const LeagueTeamAssetDetails({
    required this.assetId,
    required this.name,
    required this.playerId,
    required this.points,
    required this.boostMultiplier,
    required this.isConstructor,
    this.sessions = const [],
  });

  /// ID canónico compartido con los activos de la aplicación.
  final String assetId;
  final String name;
  final String playerId;

  /// Puntos oficiales sin multiplicar, solo si el activo pertenece a la
  /// jornada capturada.
  final double? points;
  final double boostMultiplier;
  final bool isConstructor;
  final List<LeagueTeamSessionPoints> sessions;

  double? get boostedPoints =>
      points == null ? null : points! * boostMultiplier;
}

/// Detalle de la alineación de un miembro para la jornada capturada.
///
/// Si no hay una respuesta de equipo asociada a ese miembro, [available] es
/// false y la alineación queda vacía. Nunca se reutiliza el equipo propio como
/// sustituto del de un rival.
class LeagueTeamDetails {
  const LeagueTeamDetails({
    required this.gameDayId,
    required this.available,
    required this.drivers,
    required this.constructors,
    this.teamNumber,
    this.userGuid,
    this.teamName,
    this.weekendPoints,
  });

  final int gameDayId;
  final bool available;
  final int? teamNumber;
  final String? userGuid;
  final String? teamName;
  final List<LeagueTeamAssetDetails> drivers;
  final List<LeagueTeamAssetDetails> constructors;

  /// Total explícito de la jornada, o suma ponderada de la alineación si todos
  /// sus activos tienen puntos oficiales. Los puntos de temporada no se usan.
  final double? weekendPoints;

  List<LeagueTeamAssetDetails> get assets => [...drivers, ...constructors];

  factory LeagueTeamDetails.fromSnapshot(
    Map<String, dynamic> snapshot,
    String leagueId,
    LeagueMemberTrend member,
    List<Map<String, dynamic>> assets,
  ) {
    final gameDayId = _int(snapshot['gameDay']) ?? 0;
    final metadata = _teamMetadata(snapshot['teams']);
    final memberOwner = member.key.contains(':')
        ? member.key.split(':').first
        : member.key;
    final memberTeamNo = member.key.contains(':')
        ? _int(member.key.split(':').last)
        : null;
    final snapshotGuid = _string(_value(snapshot, const ['guid']));
    final ownerTeams = metadata.where((team) {
      final declaredOwner = _string(
        _value(team, const [
          'yuserGuid',
          'userGuid',
          'user_guid',
          'guid',
          'socialId',
          'userId',
        ]),
      );
      // `teams` is the current user's own getusergamedays response. Its rows
      // often omit the owner GUID, so the captured session GUID owns those
      // rows unless they explicitly say otherwise.
      final owner = declaredOwner ?? snapshotGuid;
      final teamNo = _int(_value(team, const ['teamno', 'teamNo', 'teanNo']));
      return owner != null &&
          owner == memberOwner &&
          (memberTeamNo == null || teamNo == memberTeamNo);
    }).toList();
    Map<String, dynamic>? ownerTeam;
    if (memberTeamNo != null) {
      ownerTeam = ownerTeams.firstOrNull;
    } else if (ownerTeams.length == 1) {
      ownerTeam = ownerTeams.single;
    } else if (ownerTeams.length > 1) {
      final memberName = _normalizeName(member.name);
      final nameMatches = ownerTeams.where((team) {
        final name = _normalizeName(
          _string(_value(team, const ['teamname', 'teamName', 'name'])) ?? '',
        );
        return name.isNotEmpty && name == memberName;
      }).toList();
      if (nameMatches.length == 1) ownerTeam = nameMatches.single;
    }

    final explicitLeagueRoot = _value(snapshot, const ['leagueTeamDetails']);
    final leagueRoot = explicitLeagueRoot is Map
        ? _value(Map.from(explicitLeagueRoot), [leagueId])
        : null;
    final leagueMemberDetail = leagueRoot is Map
        ? _value(Map.from(leagueRoot), [member.key])
        : null;

    dynamic detail;
    int? teamNumber;
    String? teamName;
    String? userGuid;
    if (leagueMemberDetail != null) {
      detail = leagueMemberDetail;
      userGuid = memberOwner;
      teamNumber =
          _int(_value(ownerTeam ?? const {}, const ['teamno', 'teamNo'])) ??
          memberTeamNo;
      teamName = _string(
        _value(ownerTeam ?? const {}, const ['teamname', 'teamName', 'name']),
      );
    } else if (ownerTeam != null) {
      teamNumber = _int(
        _value(ownerTeam, const ['teamno', 'teamNo', 'teanNo']),
      );
      userGuid = _string(
        _value(ownerTeam, const [
          'yuserGuid',
          'userGuid',
          'user_guid',
          'guid',
          'socialId',
          'userId',
        ]),
      );
      teamName = _string(
        _value(ownerTeam, const ['teamname', 'teamName', 'name']),
      );
      final captured = _value(snapshot, const ['teamDetails']);
      detail = captured is Map && teamNumber != null
          ? _value(Map.from(captured), [teamNumber.toString()])
          : null;
    }

    final capturedDay =
        _int(
          detail is Map ? _value(Map.from(detail), const ['gameDay']) : null,
        ) ??
        gameDayId;
    final roster = _userTeam(detail);
    final captainMultipliers = _captainMultipliers(detail);
    if (roster.isEmpty) {
      return LeagueTeamDetails(
        gameDayId: capturedDay,
        available: false,
        teamNumber: teamNumber,
        userGuid: userGuid,
        teamName: teamName ?? _memberTeamName(member),
        drivers: const [],
        constructors: const [],
        weekendPoints: _eventPoints(
          snapshot,
          leagueId,
          member.key,
          capturedDay,
          member.name,
        ),
      );
    }

    final byPlayerId = <String, Map<String, dynamic>>{};
    for (final asset in assets) {
      final playerId = _string(
        _value(asset, const ['id', 'playerId', 'player_id']),
      );
      if (playerId != null) byPlayerId[playerId] = asset;
    }
    final picks = _rosterPicks(roster);
    final drivers = <LeagueTeamAssetDetails>[];
    final constructors = <LeagueTeamAssetDetails>[];
    for (final pick in picks) {
      final asset = byPlayerId[pick.playerId];
      if (asset == null) continue;
      final isConstructor =
          _bool(_value(asset, const ['is_constructor'])) ??
          _string(
                _value(asset, const ['position', 'position_abbreviation']),
              )?.toLowerCase().contains('constructor') ==
              true;
      final assetRound = _int(_value(asset, const ['round']));
      final points = assetRound == capturedDay
          ? _double(_value(asset, const ['GamedayPoints']))
          : null;
      final multiplier =
          pick.multiplier ?? captainMultipliers[pick.playerId] ?? 1;
      final sessions = _sessions(
        assetRound == capturedDay
            ? _value(asset, const ['SessionWisePoints', 'sessions'])
            : null,
      );
      final parsed = LeagueTeamAssetDetails(
        assetId: _string(_value(asset, const ['canonical_id'])) ?? '',
        name:
            _string(
              _value(asset, const [
                'display_name',
                'FUllName',
                'FullName',
                'TeamName',
              ]),
            ) ??
            '',
        playerId: pick.playerId,
        points: points,
        boostMultiplier: multiplier,
        isConstructor: isConstructor,
        sessions: sessions,
      );
      (isConstructor ? constructors : drivers).add(parsed);
    }

    final boardPoints = _eventPoints(
      snapshot,
      leagueId,
      member.key,
      capturedDay,
      member.name,
    );
    final lineupPoints =
        picks.isNotEmpty &&
            picks.length == drivers.length + constructors.length &&
            [...drivers, ...constructors].every((asset) => asset.points != null)
        ? [...drivers, ...constructors].fold<double>(
            0,
            (sum, asset) => sum + asset.points! * asset.boostMultiplier,
          )
        : null;
    return LeagueTeamDetails(
      gameDayId: capturedDay,
      available: true,
      teamNumber: teamNumber,
      userGuid: userGuid,
      teamName: teamName ?? _memberTeamName(member),
      drivers: List.unmodifiable(drivers),
      constructors: List.unmodifiable(constructors),
      weekendPoints: boardPoints ?? lineupPoints,
    );
  }
}

class _RosterPick {
  const _RosterPick(this.playerId, this.multiplier);
  final String playerId;
  final double? multiplier;
}

List<Map<String, dynamic>> _teamMetadata(dynamic root) {
  final rows = <Map<String, dynamic>>[];
  void visit(dynamic node) {
    if (node is Map) {
      for (final entry in node.entries) {
        if (entry.key.toString().toLowerCase() == 'mddetails') continue;
        visit(entry.value);
      }
      if (_value(node, const ['teamno', 'teamNo', 'teanNo']) != null) {
        rows.add(Map<String, dynamic>.from(node));
      }
    } else if (node is List) {
      for (final item in node) {
        visit(item);
      }
    }
  }

  visit(root);
  return rows;
}

List<dynamic> _userTeam(dynamic node) {
  if (node is Map) {
    for (final entry in node.entries) {
      if (entry.key.toString().toLowerCase() == 'userteam' &&
          entry.value is List) {
        return entry.value as List;
      }
    }
    for (final value in node.values) {
      final found = _userTeam(value);
      if (found.isNotEmpty) return found;
    }
  }
  return const [];
}

List<_RosterPick> _rosterPicks(List<dynamic> roster) {
  final result = <_RosterPick>[];
  void visit(dynamic node, {double? inheritedMultiplier}) {
    if (node is List) {
      for (final item in node) {
        visit(item, inheritedMultiplier: inheritedMultiplier);
      }
    } else if (node is Map) {
      final currentMultiplier = _pickMultiplier(node) ?? inheritedMultiplier;
      for (final entry in node.entries) {
        final normalized = entry.key.toString().toLowerCase().replaceAll(
          '_',
          '',
        );
        if (normalized == 'playerid') {
          if (entry.value is List || entry.value is Map) {
            visit(entry.value, inheritedMultiplier: currentMultiplier);
          } else {
            final id = _string(entry.value);
            if (id != null) result.add(_RosterPick(id, currentMultiplier));
          }
        } else if (entry.value is Map || entry.value is List) {
          visit(entry.value, inheritedMultiplier: currentMultiplier);
        }
      }
    } else if (node is num || node is String) {
      final id = _string(node);
      if (id != null) result.add(_RosterPick(id, inheritedMultiplier));
    }
  }

  visit(roster);
  final unique = <String, _RosterPick>{};
  for (final pick in result) {
    unique[pick.playerId] = pick;
  }
  return unique.values.toList();
}

Map<String, double> _captainMultipliers(dynamic node) {
  final result = <String, double>{};
  void visit(dynamic value) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase().replaceAll('_', '');
        final multiplier = switch (key) {
          'mgcapplayerid' => 3.0,
          'capplayerid' => 2.0,
          _ => null,
        };
        final playerId = _string(entry.value);
        if (multiplier != null && playerId != null) {
          result[playerId] = multiplier > (result[playerId] ?? 0)
              ? multiplier
              : result[playerId]!;
        }
      }
      for (final child in value.values) {
        visit(child);
      }
    } else if (value is List) {
      for (final child in value) {
        visit(child);
      }
    }
  }

  visit(node);
  return result;
}

double? _pickMultiplier(Map node) {
  final explicit = _double(
    _value(node, const [
      'boostmultiplier',
      'boostMultiplier',
      'multiplier',
      'captainMultiplier',
    ]),
  );
  if (explicit != null && explicit > 0) return explicit;
  for (final entry in node.entries) {
    final key = entry.key.toString().toLowerCase().replaceAll('_', '');
    if ((key.contains('mega') || key.startsWith('mg')) &&
        key.contains('captain') &&
        _bool(entry.value) == true) {
      return 3;
    }
  }
  for (final entry in node.entries) {
    final key = entry.key.toString().toLowerCase().replaceAll('_', '');
    if ((key.contains('captain') || key == 'iscap') &&
        _bool(entry.value) == true) {
      return 2;
    }
  }
  return null;
}

List<LeagueTeamSessionPoints> _sessions(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (session) => LeagueTeamSessionPoints(
          name:
              _string(
                _value(session, const ['sessiontype', 'name', 'session']),
              ) ??
              'Sesión',
          points: _double(_value(session, const ['points', 'GamedayPoints'])),
        ),
      )
      .toList(growable: false);
}

double? _eventPoints(
  Map<String, dynamic> snapshot,
  String leagueId,
  String memberKey,
  int day,
  String memberName,
) {
  final history = _value(snapshot, const ['leagueHistory']);
  final league = history is Map ? _value(Map.from(history), [leagueId]) : null;
  final board = league is Map
      ? _value(Map.from(league), [day.toString()])
      : null;
  final rows = _rows(board);
  final wantedGuid = memberKey.contains(':')
      ? memberKey.split(':').first
      : memberKey;
  final wantedTeamNo = memberKey.contains(':')
      ? _int(memberKey.split(':').last)
      : null;
  final matchingRows = rows.where((row) {
    final key = _string(
      _value(row, const [
        'yuserGuid',
        'userguid',
        'user_guid',
        'userid',
        'user_id',
        'guid',
        'socialid',
        'teamid',
        'entryid',
      ]),
    );
    final rowTeamNo = _int(_value(row, const ['teamno', 'teamNo']));
    return key == wantedGuid &&
        (wantedTeamNo == null || wantedTeamNo == rowTeamNo);
  }).toList();
  Map<String, dynamic>? selectedRow;
  if (matchingRows.length == 1) {
    selectedRow = matchingRows.single;
  } else if (wantedTeamNo == null && matchingRows.length > 1) {
    final nameMatches = matchingRows.where((row) {
      final rowName = _string(
        _value(row, const ['teamname', 'team_name', 'entry_name', 'name']),
      );
      return rowName != null &&
          _normalizeName(rowName) == _normalizeName(memberName);
    }).toList();
    if (nameMatches.length == 1) selectedRow = nameMatches.single;
  }
  return selectedRow == null
      ? null
      : _double(
          _value(selectedRow, const [
            'gdpoints',
            'gamedaypoints',
            'gameday_points',
            'event_points',
            'cur_points',
          ]),
        );
}

List<Map<String, dynamic>> _rows(dynamic node) {
  if (node is List) {
    return node
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
  if (node is Map) {
    for (final entry in node.entries) {
      if (const {
        'leaderboard',
        'leaderboards',
        'memrank',
        'userrank',
        'entries',
        'results',
      }.contains(entry.key.toString().toLowerCase())) {
        final rows = _rows(entry.value);
        if (rows.isNotEmpty) return rows;
      }
    }
    for (final value in node.values) {
      final rows = _rows(value);
      if (rows.isNotEmpty) return rows;
    }
  }
  return const [];
}

String? _memberTeamName(LeagueMemberTrend member) =>
    member.name.isEmpty ? null : member.name;

String _normalizeName(String value) {
  try {
    return Uri.decodeComponent(
      value.replaceAll('+', ' '),
    ).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  } catch (_) {
    return value
        .replaceAll('+', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }
}

dynamic _value(Map map, List<String> keys) {
  final normalized = keys
      .map((key) => key.toLowerCase().replaceAll('_', ''))
      .toSet();
  for (final entry in map.entries) {
    if (!normalized.contains(
      entry.key.toString().toLowerCase().replaceAll('_', ''),
    )) {
      continue;
    }
    if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
      return entry.value;
    }
  }
  return null;
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
double? _double(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
String? _string(dynamic value) =>
    value == null || value.toString().trim().isEmpty
    ? null
    : value.toString().trim();
bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value == 1 || value == '1' || value == 'true') return true;
  if (value == 0 || value == '0' || value == 'false') return false;
  return null;
}
