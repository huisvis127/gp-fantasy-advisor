import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FantasyAuthException implements Exception {
  FantasyAuthException(
    this.message, {
    this.likelyAntiBot = false,
    this.canTryBrowserLogin = false,
  });

  final String message;
  final bool likelyAntiBot;
  final bool canTryBrowserLogin;

  @override
  String toString() => 'FantasyAuthException: $message';
}

class FantasyAuthService {
  FantasyAuthService(this._dio,
      {required String loginBaseUrl, FlutterSecureStorage? storage})
      : _loginBaseUrl = loginBaseUrl,
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final String _loginBaseUrl;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'f1_fantasy_subscription_token';
  static const _sessionKey = 'f1_fantasy_session_id';
  static const _snapshotKey = 'f1_fantasy_web_snapshot';

  /// apiKey pública que usa la propia web de formula1.com para el login
  /// (documentada por la comunidad: proyectos f1-fantasy-api y el cheat
  /// sheet de endpoints referenciados en docs/archive/PLAN_DESARROLLO.md sección 3.1).
  static const _publicApiKey = 'fLRgnHF4kXTBRSPjnKSVefdWaMzTB1DP';

  Future<String> loginWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      // Flujo real (Plan A, un solo paso): POST by-password con la apiKey
      // pública; la respuesta trae data.subscriptionToken.
      final response = await _dio.post<Map<String, dynamic>>(
        '$_loginBaseUrl/v2/account/subscriber/authenticate/by-password',
        data: {'Login': username, 'Password': password},
        options: Options(headers: {
          'apiKey': _publicApiKey,
          'Content-Type': 'application/json',
          'User-Agent': 'RaceControl',
        }),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final token = data?['subscriptionToken']?.toString();
      if (token == null || token.isEmpty) {
        throw FantasyAuthException(
          'Login aceptado pero sin subscriptionToken en la respuesta '
          '(claves recibidas: ${response.data?.keys.join(', ') ?? 'ninguna'}). '
          'Usa el acceso con navegador.',
          canTryBrowserLogin: true,
        );
      }

      await _storage.write(key: _tokenKey, value: token);
      final subscriberId = data?['subscriberId']?.toString();
      if (subscriberId != null) {
        await _storage.write(key: _sessionKey, value: subscriberId);
      }
      return token;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final blocked = statusCode == 403 || statusCode == 429;
      final unauthorized = statusCode == 401;
      final message = switch (statusCode) {
        401 => 'No se pudo iniciar sesion. Revisa el correo y la contrasena. '
            'Si en la web oficial si funciona, usa el acceso con navegador.',
        403 ||
        429 =>
          'Formula1.com ha bloqueado el acceso directo. Usa el acceso con navegador.',
        _ =>
          'No se pudo conectar con Formula1.com. Revisa la conexion e intentalo de nuevo.',
      };
      throw FantasyAuthException(
        message,
        likelyAntiBot: blocked,
        canTryBrowserLogin: blocked || unauthorized,
      );
    }
  }

  Future<void> saveExternalToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readStoredToken() => _storage.read(key: _tokenKey);

  Future<void> saveSessionSnapshot(String snapshotJson) async {
    await _storage.write(key: _snapshotKey, value: snapshotJson);
  }

  Future<String?> readSessionSnapshot() => _storage.read(key: _snapshotKey);

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _snapshotKey);
  }
}
