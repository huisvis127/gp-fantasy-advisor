import 'package:dio/dio.dart';

import '../../domain/models/constructor_team.dart';
import '../../domain/models/driver.dart';
import '../../domain/models/qualifying_result.dart';
import '../../domain/models/race.dart';
import '../../domain/models/race_result.dart';

/// Cliente de Jolpica-F1 (sucesor de Ergast). Resultados históricos,
/// clasificaciones y calendario. Sin autenticación. Respetar rate limit
/// (~500 req/hora sin key): agrupar peticiones y dejar que
/// `DataRepository` cachee agresivamente (sección 3 del plan).
class JolpicaApi {
  JolpicaApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<List<Race>> getSeasonCalendar(int season) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_baseUrl/$season.json');
    final races = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    return races
        .map((r) => Race.fromJolpica(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<RaceResult>> getRaceResults(int season, int round) async {
    final response = await _dio
        .get<Map<String, dynamic>>('$_baseUrl/$season/$round/results.json');
    final raceTable = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    if (raceTable.isEmpty) return [];
    final resultsJson =
        (raceTable.first as Map<String, dynamic>)['Results'] as List<dynamic>;
    return resultsJson
        .map((r) =>
            RaceResult.fromJolpica(r as Map<String, dynamic>, season, round))
        .toList();
  }

  /// Descarga todos los resultados de una temporada en una sola petición.
  Future<List<RaceResult>> getSeasonResults(int season) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/$season/results.json',
      queryParameters: const {'limit': 2000},
    );
    final races = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    final result = <RaceResult>[];
    for (final raceRaw in races) {
      final race = raceRaw as Map<String, dynamic>;
      final round = int.parse(race['round'].toString());
      final rows = (race['Results'] as List<dynamic>?) ?? const [];
      result.addAll(rows.map(
        (row) => RaceResult.fromJolpica(
          row as Map<String, dynamic>,
          season,
          round,
        ),
      ));
    }
    return result;
  }

  Future<List<QualifyingResult>> getQualifyingResults(
      int season, int round) async {
    final response = await _dio
        .get<Map<String, dynamic>>('$_baseUrl/$season/$round/qualifying.json');
    final raceTable = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    if (raceTable.isEmpty) return [];
    final qualiJson = (raceTable.first
        as Map<String, dynamic>)['QualifyingResults'] as List<dynamic>;
    return qualiJson
        .map((q) => QualifyingResult.fromJolpica(
            q as Map<String, dynamic>, season, round))
        .toList();
  }

  /// Descarga toda la clasificación de una temporada en una petición.
  Future<List<QualifyingResult>> getSeasonQualifying(int season) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/$season/qualifying.json',
      queryParameters: const {'limit': 2000},
    );
    final races = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    final result = <QualifyingResult>[];
    for (final raceRaw in races) {
      final race = raceRaw as Map<String, dynamic>;
      final round = int.parse(race['round'].toString());
      final rows = (race['QualifyingResults'] as List<dynamic>?) ?? const [];
      result.addAll(rows.map(
        (row) => QualifyingResult.fromJolpica(
          row as Map<String, dynamic>,
          season,
          round,
        ),
      ));
    }
    return result;
  }

  Future<List<Driver>> getDrivers(int season) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_baseUrl/$season/drivers.json');
    final driversJson =
        _mrData(response)['DriverTable']['Drivers'] as List<dynamic>;
    // Jolpica no da el constructorId en este endpoint: se completa cruzando
    // con los resultados de la última carrera conocida en DataRepository.
    return driversJson
        .map((d) => Driver.fromJolpica(d as Map<String, dynamic>, ''))
        .toList();
  }

  Future<List<ConstructorTeam>> getConstructors(int season) async {
    final response = await _dio
        .get<Map<String, dynamic>>('$_baseUrl/$season/constructors.json');
    final json =
        _mrData(response)['ConstructorTable']['Constructors'] as List<dynamic>;
    return json
        .map((c) => ConstructorTeam.fromJolpica(c as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _mrData(Response<Map<String, dynamic>> response) {
    return response.data!['MRData'] as Map<String, dynamic>;
  }
}
