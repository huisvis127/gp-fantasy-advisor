import 'dart:convert';

import '../../domain/models/my_team.dart';
import '../sources/fantasy_api.dart';
import '../sources/fantasy_auth_service.dart';

/// Error de importación con mensaje accionable: siempre dice QUÉ llegó de la
/// API para poder ajustar el parseo si Formula1 cambia el formato (riesgo
/// alto documentado en la sección 8 del plan).
class TeamImportException implements Exception {
  TeamImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Importa el equipo real del usuario desde la API no oficial de F1 Fantasy
/// (la pieza de la Fase 4 del plan que faltaba: el login guardaba el token
/// pero NADIE llamaba después a picked_teams ni rellenaba MyTeam).
///
/// Flujo: token guardado -> GET picked_teams -> ids internos del Fantasy ->
/// GET players (público) para traducir id -> nombre -> match por nombre con
/// nuestro catálogo (ids de Jolpica) -> MyTeam listo para guardar.
class TeamImportService {
  TeamImportService({required FantasyApi api, required FantasyAuthService auth})
      : _api = api,
        _auth = auth;

  final FantasyApi _api;
  final FantasyAuthService _auth;

  /// `driverCatalog` / `constructorCatalog`: id Jolpica -> nombre legible
  /// (del catálogo de standings que la app ya tiene cargado).
  Future<MyTeam> importMyTeam({
    required int season,
    required Map<String, String> driverCatalog,
    required Map<String, String> constructorCatalog,
  }) async {
    final token = await _auth.readStoredToken();
    final snapshotRaw = await _auth.readSessionSnapshot();
    if ((token == null || token.isEmpty) &&
        (snapshotRaw == null || snapshotRaw.isEmpty)) {
      throw TeamImportException(
          'No hay sesión guardada. Inicia sesión primero (Ajustes).');
    }

    // 1. Equipo elegido (privado).
    late Map<String, dynamic> pickedJson;
    if (snapshotRaw != null && snapshotRaw.isNotEmpty) {
      try {
        final snapshot = jsonDecode(snapshotRaw) as Map<String, dynamic>;
        final capturedTeams = snapshot['teamDetails'] ?? snapshot['teams'];
        pickedJson = Map<String, dynamic>.from(
          capturedTeams as Map? ?? const <String, dynamic>{},
        );
      } catch (_) {
        throw TeamImportException(
            'La sesión guardada está dañada. Inicia sesión de nuevo.');
      }
    } else {
      try {
        pickedJson = await _api.getPickedTeams(
          season: season,
          bearerToken: token!,
        );
      } catch (e) {
        throw TeamImportException(
            'La API del Fantasy rechazó la petición del equipo '
            '(¿sesión caducada?). Vuelve a iniciar sesión. Detalle: $e');
      }
    }

    var pickedPlayers = _findPickedPlayerIds(pickedJson);
    if (pickedPlayers.isEmpty) {
      throw TeamImportException(
          'Respuesta recibida pero sin equipo dentro. Claves de la respuesta: '
          '${_describeKeys(pickedJson)}. Envíame esto para ajustar el parseo.');
    }
    final captainId = _findCaptainId(pickedJson);
    if (captainId != null) {
      pickedPlayers = pickedPlayers
          .map((picked) => _PickedPlayer(
                playerId: picked.playerId,
                isBoosted: picked.isBoosted || picked.playerId == captainId,
              ))
          .toList();
    }

    // 2. Catálogo público del juego para traducir ids internos -> nombres.
    var players = const <Map<String, dynamic>>[];
    try {
      players = await _api.getPlayersRaw(season);
    } catch (_) {
      // Sin players no podemos traducir ids: mejor decirlo claro.
      throw TeamImportException(
          'Tu equipo llegó (${pickedPlayers.length} fichajes) pero el listado '
          'público de jugadores no respondió, así que no puedo traducir los '
          'ids. Reintenta con conexión estable.');
    }
    final playerById = <String, Map<String, dynamic>>{};
    for (final p in players) {
      final id = (p['id'] ?? p['player_id'])?.toString();
      if (id != null) playerById[id] = p;
    }

    // 3. Traducción id interno -> nuestro id de Jolpica por nombre.
    final driverIds = <String>[];
    final constructorIds = <String>[];
    final unmatched = <String>[];
    String? boostedDriverId;

    for (final picked in pickedPlayers) {
      final player = playerById[picked.playerId];
      if (player == null) {
        unmatched.add('id ${picked.playerId} (no está en players)');
        continue;
      }
      final isConstructor = _isConstructor(player);
      final name = _playerName(player);
      final matchedId = isConstructor
          ? _matchByName(name, constructorCatalog)
          : _matchByName(name, driverCatalog);
      if (matchedId == null) {
        unmatched.add(name);
        continue;
      }
      if (isConstructor) {
        constructorIds.add(matchedId);
      } else {
        driverIds.add(matchedId);
        if (picked.isBoosted) boostedDriverId = matchedId;
      }
    }

    if (driverIds.length != 5 || constructorIds.length != 2) {
      throw TeamImportException(
          'No pude emparejar ningún fichaje con el catálogo. '
          'Actualiza los datos y vuelve a intentarlo.');
    }

    final budget = _findBudget(pickedJson);

    return MyTeam(
      driverIds: driverIds,
      constructorIds: constructorIds,
      remainingBudgetMillions: budget ?? 0,
      boostedDriverId: boostedDriverId,
      source: MyTeamSource.importedApi,
    );
  }

  // ---- Parseo defensivo (la API no está documentada) ----

  /// Busca recursivamente la primera lista de "picked players" plausible.
  List<_PickedPlayer> _findPickedPlayerIds(dynamic node) {
    if (node is Map<String, dynamic>) {
      for (final entry in node.entries) {
        final key = entry.key.toLowerCase();
        if (entry.value is List &&
            (key.contains('picked_player') || key == 'players_picked')) {
          final result = _parsePickedList(entry.value as List);
          if (result.isNotEmpty) return result;
        }
      }
      for (final value in node.values) {
        final result = _findPickedPlayerIds(value);
        if (result.isNotEmpty) return result;
      }
    } else if (node is List) {
      final direct = _parsePickedList(node);
      if (direct.isNotEmpty) return direct;
      for (final item in node) {
        final result = _findPickedPlayerIds(item);
        if (result.isNotEmpty) return result;
      }
    } else if (node is String) {
      final text = node.trim();
      if (text.startsWith('{') || text.startsWith('[')) {
        try {
          return _findPickedPlayerIds(jsonDecode(text));
        } catch (_) {
          // Not every string beginning with a bracket is JSON.
        }
      }
    }
    return const [];
  }

  List<_PickedPlayer> _parsePickedList(List raw) {
    final out = <_PickedPlayer>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final normalized = <String, dynamic>{
          for (final entry in item.entries)
            entry.key.toLowerCase().replaceAll('_', ''): entry.value,
        };
        final rawId = normalized['playerid'] ?? normalized['id'];
        // A team container also uses `playerid`, but its value is the list of
        // seven picks. Let the recursive walk enter that list instead of
        // turning the whole collection into one invalid identifier.
        if (rawId is Map || rawId is List || rawId == null) continue;
        final id = rawId.toString();
        final boosted = item.entries.any((e) =>
            (e.key.toLowerCase().contains('captain') ||
                e.key.toLowerCase().contains('boost') ||
                e.key.toLowerCase().contains('turbo') ||
                e.key.toLowerCase().contains('mega')) &&
            (e.value == true || e.value == 1 || e.value == '1'));
        out.add(_PickedPlayer(playerId: id, isBoosted: boosted));
      } else if (item is num || item is String) {
        out.add(_PickedPlayer(playerId: item.toString(), isBoosted: false));
      }
    }
    return out;
  }

  double? _findBudget(dynamic node) {
    if (node is Map<String, dynamic>) {
      for (final entry in node.entries) {
        final key = entry.key.toLowerCase();
        if (entry.value is num &&
            (key.contains('budget') ||
                key.contains('balance') ||
                key == 'teambal' ||
                key == 'team_bal')) {
          final value = (entry.value as num).toDouble();
          // Algunas versiones dan décimas de millón.
          return value > 120 ? value / 10.0 : value;
        }
      }
      for (final value in node.values) {
        final found = _findBudget(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findBudget(item);
        if (found != null) return found;
      }
    } else if (node is String) {
      final text = node.trim();
      if (text.startsWith('{') || text.startsWith('[')) {
        try {
          return _findBudget(jsonDecode(text));
        } catch (_) {
          // Ignore non-JSON strings.
        }
      }
    }
    return null;
  }

  String? _findCaptainId(dynamic node) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString().toLowerCase().replaceAll('_', '');
        if ((key == 'capplayerid' || key == 'mgcapplayerid') &&
            entry.value != null) {
          return entry.value.toString();
        }
      }
      for (final value in node.values) {
        final found = _findCaptainId(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _findCaptainId(value);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool _isConstructor(Map<String, dynamic> player) {
    if (player['is_constructor'] == true) return true;
    final position = (player['position'] ?? player['position_abbreviation'])
        ?.toString()
        .toLowerCase();
    return position != null &&
        (position.contains('constructor') || position == 'cn');
  }

  String _playerName(Map<String, dynamic> player) {
    final display = (player['display_name'] ??
            player['full_name'] ??
            player['team_name'] ??
            '${player['first_name'] ?? ''} ${player['last_name'] ?? ''}')
        .toString()
        .trim();
    return display.isEmpty ? player.toString() : display;
  }

  /// Empareja por nombre normalizado: coincide si el nombre del catálogo
  /// contiene el del Fantasy o viceversa (apellido suele bastar).
  String? _matchByName(String fantasyName, Map<String, String> catalog) {
    final target = _normalize(fantasyName);
    if (target.isEmpty) return null;
    String? best;
    var bestLen = 0;
    for (final entry in catalog.entries) {
      final candidate = _normalize(entry.value);
      if (candidate.contains(target) || target.contains(candidate)) {
        if (candidate.length > bestLen) {
          best = entry.key;
          bestLen = candidate.length;
        }
        continue;
      }
      // Último token (apellido) como respaldo.
      final lastToken = target.split(' ').last;
      if (lastToken.length >= 4 && candidate.contains(lastToken)) {
        best ??= entry.key;
      }
    }
    return best;
  }

  String _normalize(String text) {
    const accents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const plain = 'aaaaaeeeeiiiiooooouuuunc';
    var out = text.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], plain[i]);
    }
    return out
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _describeKeys(dynamic node, [int depth = 0]) {
    if (depth > 2) return '…';
    if (node is Map<String, dynamic>) {
      return node.entries
          .take(8)
          .map((e) => '${e.key}:${_describeKeys(e.value, depth + 1)}')
          .join(', ');
    }
    if (node is List) return '[${node.length}]';
    return node.runtimeType.toString();
  }
}

class _PickedPlayer {
  const _PickedPlayer({required this.playerId, required this.isBoosted});

  final String playerId;
  final bool isBoosted;
}
