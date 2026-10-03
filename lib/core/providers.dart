import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/data_repository.dart';
import '../data/repositories/team_import_service.dart';
import '../data/sources/fantasy_api.dart';
import '../data/sources/fantasy_auth_service.dart';
import '../data/sources/jolpica_api.dart';
import '../data/sources/openf1_api.dart';
import 'remote_config.dart';

/// Cableado de dependencias (Riverpod). Los providers de más arriba
/// (repository, engine, optimizer) dependen de estos; se resuelven una vez
/// al arrancar la app en main.dart mediante overrides tras `RemoteConfig.load`.

/// Cliente HTTP con timeouts explícitos: sin ellos una API caída dejaba la
/// app "cargando" indefinidamente y parecía que no cogía ninguna información.
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
  ));
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Se sobreescribe en main.dart una vez cargada la config remota real;
/// este valor por defecto solo evita crashear si algún test no lo overridea.
final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  throw UnimplementedError(
      'remoteConfigProvider debe sobreescribirse en main()');
});

final jolpicaApiProvider = Provider<JolpicaApi>((ref) {
  final config = ref.watch(remoteConfigProvider);
  return JolpicaApi(ref.watch(dioProvider), baseUrl: config.jolpicaBase);
});

final openF1ApiProvider = Provider<OpenF1Api>((ref) {
  final config = ref.watch(remoteConfigProvider);
  return OpenF1Api(ref.watch(dioProvider), baseUrl: config.openF1Base);
});

final fantasyApiProvider = Provider<FantasyApi>((ref) {
  final config = ref.watch(remoteConfigProvider);
  return FantasyApi(ref.watch(dioProvider),
      publicBaseUrl: config.fantasyPublicBase);
});

final fantasyAuthServiceProvider = Provider<FantasyAuthService>((ref) {
  final config = ref.watch(remoteConfigProvider);
  return FantasyAuthService(ref.watch(dioProvider),
      loginBaseUrl: config.fantasyLoginBase);
});

final teamImportServiceProvider = Provider<TeamImportService>((ref) {
  return TeamImportService(
    api: ref.watch(fantasyApiProvider),
    auth: ref.watch(fantasyAuthServiceProvider),
  );
});

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  return DataRepository(
    db: ref.watch(databaseProvider),
    jolpica: ref.watch(jolpicaApiProvider),
    openF1: ref.watch(openF1ApiProvider),
    fantasyApi: ref.watch(fantasyApiProvider),
  );
});

/// Temporada activa. Cambiar aquí cuando empiece 2027, o leerlo de config
/// remota si se prefiere no tocar código cada año.
final currentSeasonProvider = Provider<int>((ref) => 2026);
