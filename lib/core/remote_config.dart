import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'constants.dart';

/// Config remota (sección 3, notas de implementación): endpoints y feature
/// flags en un JSON alojado fuera de la app (GitHub Pages del repo) para
/// poder corregir URLs rotas sin publicar una nueva versión en Play.
///
/// Si la descarga falla (sin conexión, URL caída), se usa el fallback
/// embebido en assets/remote_config_fallback.json.
class RemoteConfig {
  RemoteConfig._(this._data);

  final Map<String, dynamic> _data;

  static const String _remoteUrl =
      'https://raw.githubusercontent.com/huisvis127/gp-fantasy-advisor/main/assets/remote_config_fallback.json';

  static Future<RemoteConfig> load({Dio? dio}) async {
    final client = dio ?? Dio();
    try {
      final response = await client
          .get<String>(
            _remoteUrl,
            options: Options(responseType: ResponseType.plain),
            cancelToken: null,
          )
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200 && response.data != null) {
        return RemoteConfig._(
            jsonDecode(response.data!) as Map<String, dynamic>);
      }
    } catch (_) {
      // Sin red o URL caída: seguimos con el fallback local.
    }
    final fallbackRaw =
        await rootBundle.loadString(AssetPaths.remoteConfigFallback);
    return RemoteConfig._(jsonDecode(fallbackRaw) as Map<String, dynamic>);
  }

  String get jolpicaBase => _data['endpoints']['jolpica_base'] as String;
  String get openF1Base => _data['endpoints']['openf1_base'] as String;
  String get fantasyPublicBase =>
      _data['endpoints']['fantasy_public_base'] as String;
  String get fantasyLoginBase =>
      _data['endpoints']['fantasy_login_base'] as String;

  bool get loginPlanAEnabled =>
      (_data['feature_flags']?['login_plan_a_enabled'] as bool?) ?? true;
  bool get loginPlanBEnabled =>
      (_data['feature_flags']?['login_plan_b_webview_enabled'] as bool?) ??
      true;
}
