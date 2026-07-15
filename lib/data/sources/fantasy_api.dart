import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/models/fantasy_price.dart';

/// Cliente de la API no oficial de F1 Fantasy (sección 3.1 del plan).
/// - Endpoints públicos (`players`, `teams`): precios de mercado, sin auth.
/// - Endpoints privados (`picked_teams`, `league_entrants`, `leaderboards`,
///   `boosters`): requieren el token de sesión obtenido por el login
///   (Plan A en `FantasyAuthService`, o Plan B WebView en la UI).
///
/// Riesgo alto: API no documentada, puede cambiar sin aviso. Todas las URLs
/// se leen de `RemoteConfig` para poder corregirlas sin publicar versión.
class FantasyApi {
  FantasyApi(this._dio, {required String publicBaseUrl})
      : _publicBaseUrl = publicBaseUrl;

  final Dio _dio;
  final String _publicBaseUrl;

  /// Precios actuales de pilotos y constructores. Público, sin token.
  Future<List<FantasyPrice>> getCurrentPrices(int season) async {
    final assets = await _getOfficialAssets();
    return assets.map((json) {
      final isConstructor = json['is_constructor'] == true;
      final rawPrice = (json['price'] as num?)?.toDouble() ?? 0;
      return FantasyPrice(
        assetId: json['canonical_id'].toString(),
        assetType: isConstructor
            ? FantasyAssetType.constructor
            : FantasyAssetType.driver,
        season: season,
        round: (json['round'] as num?)?.toInt() ?? 0,
        priceMillions: rawPrice > 40 ? rawPrice / 10.0 : rawPrice,
      );
    }).toList();
  }

  /// Cabeceras de autenticación tolerantes: esta API no oficial ha usado a
  /// lo largo del tiempo Bearer, la cookie `login-session` y la cabecera
  /// `X-F1-COOKIE-DATA` (base64 del mismo JSON). Se envían las tres formas;
  /// las que sobren el servidor las ignora.
  Options _authOptions(String token) {
    final cookieJson = jsonEncode({
      'data': {'subscriptionToken': token},
    });
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Cookie': 'login-session=${Uri.encodeComponent(cookieJson)}',
      'X-F1-COOKIE-DATA': base64Encode(utf8.encode(cookieJson)),
    });
  }

  /// Lista cruda de jugadores/constructores del juego (público, sin token):
  /// ids internos del Fantasy, nombres, precios y si es constructor. Se usa
  /// para mapear los ids del equipo importado a nuestros ids de Jolpica.
  Future<List<Map<String, dynamic>>> getPlayersRaw(int season) async {
    return _getOfficialAssets();
  }

  /// La web 2026 publica precios y catálogo como feeds JSON. Primero se
  /// resuelve la jornada actual desde el calendario y después se descarga
  /// `drivers/{gameday}_en.json`, que incluye pilotos y constructores.
  Future<List<Map<String, dynamic>>> _getOfficialAssets() async {
    final scheduleResponse = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/feeds/v2/schedule/raceday_en.json',
    );
    final scheduleData = scheduleResponse.data?['Data'];
    final fixtures = scheduleData is Map
        ? (scheduleData['fixtures'] as List<dynamic>? ?? const [])
        : const <dynamic>[];
    final current = fixtures.cast<Map>().firstWhere(
          (row) => row['GDIsCurrent'] == 1 || row['GDIsCurrent'] == '1',
          orElse: () => fixtures.cast<Map>().lastWhere(
                (row) => row['GDIsLocked'] == 1 || row['GDIsLocked'] == '1',
                orElse: () => const {'GamedayId': 1},
              ),
        );
    final gameDayId = int.tryParse(current['GamedayId'].toString()) ?? 1;

    final assetsResponse = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/feeds/drivers/${gameDayId}_en.json',
    );
    final data = assetsResponse.data?['Data'];
    final rawAssets = data is Map
        ? (data['Value'] as List<dynamic>? ?? const [])
        : const <dynamic>[];

    return rawAssets.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final skill = int.tryParse(item['Skill'].toString()) ?? 1;
      final isConstructor = skill == 2 ||
          item['PositionName']?.toString().toUpperCase() == 'CONSTRUCTOR';
      final name = (item['FUllName'] ??
              item['FullName'] ??
              item['TeamName'] ??
              item['DisplayName'] ??
              '')
          .toString();
      return <String, dynamic>{
        ...item,
        'id': (item['PlayerId'] ?? item['id']).toString(),
        'canonical_id': _canonicalAssetId(name, isConstructor: isConstructor),
        'is_constructor': isConstructor,
        'position': isConstructor ? 'constructor' : 'driver',
        'price': item['Value'] ?? item['price'] ?? 0,
        'round': gameDayId,
        'display_name': name,
        'team_name': (item['TeamName'] ?? name).toString(),
      };
    }).toList();
  }

  String _canonicalAssetId(String name, {required bool isConstructor}) {
    final normalized = _normalize(name);
    if (isConstructor) {
      const aliases = {
        'alpine': 'alpine',
        'aston martin': 'aston_martin',
        'audi': 'audi',
        'cadillac': 'cadillac',
        'ferrari': 'ferrari',
        'haas': 'haas',
        'mclaren': 'mclaren',
        'mercedes': 'mercedes',
        'racing bulls': 'rb',
        'red bull': 'red_bull',
        'williams': 'williams',
      };
      for (final entry in aliases.entries) {
        if (normalized.contains(entry.key)) return entry.value;
      }
    }
    if (normalized.contains('max verstappen')) return 'max_verstappen';
    if (normalized.contains('arvid lindblad')) return 'arvid_lindblad';
    final parts =
        normalized.split(' ').where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? normalized.replaceAll(' ', '_') : parts.last;
  }

  String _normalize(String value) {
    const accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const plain = 'aaaaaeeeeiiiiooooouuuunc';
    var result = value.toLowerCase().trim();
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], plain[i]);
    }
    return result
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<Map<String, dynamic>> getPickedTeams({
    required int season,
    required String bearerToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/$season/picked_teams',
      queryParameters: {
        'my_current_picked_teams': 'true',
        'my_next_picked_teams': 'true',
      },
      options: _authOptions(bearerToken),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getLeagueEntrants({
    required int season,
    required String bearerToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/$season/league_entrants',
      options: Options(headers: {'Authorization': 'Bearer $bearerToken'}),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getLeagueLeaderboard({
    required int season,
    required String leagueId,
    required String bearerToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/$season/leaderboards/leagues',
      queryParameters: {'league_id': leagueId},
      options: Options(headers: {'Authorization': 'Bearer $bearerToken'}),
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getBoosters({
    required int season,
    required String bearerToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_publicBaseUrl/$season/boosters',
      options: Options(headers: {'Authorization': 'Bearer $bearerToken'}),
    );
    return response.data ?? {};
  }
}
