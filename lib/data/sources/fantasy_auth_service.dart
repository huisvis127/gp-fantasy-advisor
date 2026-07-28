import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FantasyAuthService {
  FantasyAuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'f1_fantasy_subscription_token';
  static const _snapshotKey = 'f1_fantasy_web_snapshot';

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
    await _storage.delete(key: _snapshotKey);
  }
}
