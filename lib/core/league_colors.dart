import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeagueTeamColor {
  const LeagueTeamColor(this.name, this.color);

  final String name;
  final Color color;
}

/// User-selectable colors shared by standings, charts, and the medal table.
class LeagueColors {
  LeagueColors._();

  static const palette = <LeagueTeamColor>[
    LeagueTeamColor('Rojo coral', Color(0xFFE85D75)),
    LeagueTeamColor('Naranja mango', Color(0xFFF28C45)),
    LeagueTeamColor('Ámbar', Color(0xFFE3B341)),
    LeagueTeamColor('Lima', Color(0xFFA8C66C)),
    LeagueTeamColor('Verde salvia', Color(0xFF62B58F)),
    LeagueTeamColor('Turquesa', Color(0xFF45B9B0)),
    LeagueTeamColor('Azul cielo', Color(0xFF58A6D6)),
    LeagueTeamColor('Azul océano', Color(0xFF5279C7)),
    LeagueTeamColor('Índigo', Color(0xFF7967C8)),
    LeagueTeamColor('Violeta', Color(0xFFA06BCB)),
    LeagueTeamColor('Rosa', Color(0xFFD86FA8)),
    LeagueTeamColor('Cereza', Color(0xFFC94F69)),
    LeagueTeamColor('Terracota', Color(0xFFC97852)),
    LeagueTeamColor('Mostaza', Color(0xFFC6A34A)),
    LeagueTeamColor('Musgo', Color(0xFF7E9E54)),
    LeagueTeamColor('Esmeralda', Color(0xFF348E70)),
    LeagueTeamColor('Cian', Color(0xFF369CAA)),
    LeagueTeamColor('Zafiro', Color(0xFF4466A8)),
    LeagueTeamColor('Ciruela', Color(0xFF80538F)),
    LeagueTeamColor('Malva', Color(0xFFAA829B)),
  ];

  static int indexForIdentity(String leagueId, String memberKey) =>
      _stableIndex('$leagueId\u0000$memberKey');

  static Color forIdentity(String leagueId, String memberKey) =>
      palette[indexForIdentity(leagueId, memberKey)].color;

  static String preferenceKey(String leagueId) =>
      'league_team_colors_${base64Url.encode(utf8.encode(leagueId))}';

  static Future<Map<String, int>> load(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferenceKey(leagueId));
    if (raw == null) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: (entry.value as int)
                .clamp(0, palette.length - 1)
                .toInt(),
      };
    } on FormatException {
      return <String, int>{};
    }
  }

  static Future<void> save(
    String leagueId,
    String memberKey,
    int paletteIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final colors = await load(leagueId);
    colors[memberKey] = paletteIndex.clamp(0, palette.length - 1).toInt();
    await prefs.setString(preferenceKey(leagueId), jsonEncode(colors));
  }

  static int _stableIndex(String value) {
    // FNV-1a gives a repeatable fallback independent of current standings order.
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash % palette.length;
  }
}
