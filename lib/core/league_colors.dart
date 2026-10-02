import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeagueTeamColor {
  const LeagueTeamColor(this.name, this.color, {this.isNeon = false});

  final String name;
  final Color color;
  final bool isNeon;
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
    LeagueTeamColor('Rojo neón', Color(0xFFFF1838), isNeon: true),
    LeagueTeamColor('Naranja neón', Color(0xFFFF7000), isNeon: true),
    LeagueTeamColor('Ámbar neón', Color(0xFFFFB833), isNeon: true),
    LeagueTeamColor('Amarillo neón', Color(0xFFFFD700), isNeon: true),
    LeagueTeamColor('Lima neón', Color(0xFFC8FF00), isNeon: true),
    LeagueTeamColor('Verde neón', Color(0xFF76FF03), isNeon: true),
    LeagueTeamColor('Esmeralda neón', Color(0xFF00E096), isNeon: true),
    LeagueTeamColor('Menta neón', Color(0xFF00FFAD), isNeon: true),
    LeagueTeamColor('Turquesa neón', Color(0xFF27F4D2), isNeon: true),
    LeagueTeamColor('Cian neón', Color(0xFF00E5FF), isNeon: true),
    LeagueTeamColor('Cielo neón', Color(0xFF40C4FF), isNeon: true),
    LeagueTeamColor('Azul neón', Color(0xFF448AFF), isNeon: true),
    LeagueTeamColor('Índigo neón', Color(0xFF7C83FF), isNeon: true),
    LeagueTeamColor('Violeta neón', Color(0xFF9B5CFF), isNeon: true),
    LeagueTeamColor('Lavanda neón', Color(0xFFBF80FF), isNeon: true),
    LeagueTeamColor('Fucsia neón', Color(0xFFFF3CB8), isNeon: true),
    LeagueTeamColor('Rosa neón', Color(0xFFFF6AC1), isNeon: true),
    LeagueTeamColor('Coral neón', Color(0xFFFF5268), isNeon: true),
    LeagueTeamColor('Mandarina neón', Color(0xFFFFA040), isNeon: true),
    LeagueTeamColor('Limón neón', Color(0xFFEEFF41), isNeon: true),
  ];

  static int indexForIdentity(String leagueId, String memberKey) =>
      20 + _stableIndex('$leagueId\u0000$memberKey') % 20;

  static Color forIdentity(String leagueId, String memberKey) =>
      palette[indexForIdentity(leagueId, memberKey)].color;

  /// Mezcla neón y normal sin cambiar los índices de preferencias anteriores.
  static final displayOrder = [
    for (var i = 0; i < 20; i++) ...[i + 20, i],
  ];

  static Color resolve(
    String leagueId,
    String memberKey,
    Map<String, int> saved,
  ) {
    final index = saved[memberKey] ?? saved[memberKey.split(':').first];
    return index == null
        ? forIdentity(leagueId, memberKey)
        : palette[index.clamp(0, palette.length - 1)].color;
  }

  static Color textColor(Color color, Brightness brightness) {
    final background = brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF101015);
    var hsl = HSLColor.fromColor(color);
    for (var i = 0; i < 100; i++) {
      final foreground = hsl.toColor();
      final a = foreground.computeLuminance();
      final b = background.computeLuminance();
      final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      if (contrast >= 4.5) return foreground;
      hsl = hsl.withLightness(
        (hsl.lightness + (brightness == Brightness.light ? -.01 : .01)).clamp(
          0.0,
          1.0,
        ),
      );
    }
    return hsl.toColor();
  }

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
