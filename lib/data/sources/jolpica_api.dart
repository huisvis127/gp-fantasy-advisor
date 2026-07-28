import 'dart:async';

import 'package:dio/dio.dart';

import '../../domain/models/constructor_team.dart';
import '../../domain/models/driver.dart';
import '../../domain/models/qualifying_result.dart';
import '../../domain/models/race.dart';
import '../../domain/models/race_result.dart';

/// Cliente de Jolpica-F1 (sucesor de Ergast). Serializa y pagina las
/// peticiones para respetar el limite publico del servicio.
class JolpicaApi {
  JolpicaApi(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  static const _pageSize = 100;
  static const _minimumRequestGap = Duration(milliseconds: 300);

  final Dio _dio;
  final String _baseUrl;
  Future<void> _requestTail = Future<void>.value();
  DateTime? _lastRequestStarted;

  Future<List<Race>> getSeasonCalendar(int season) async {
    final response = await _get('$_baseUrl/$season.json');
    final races = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    return races
        .map((r) => Race.fromJolpica(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<RaceResult>> getRaceResults(int season, int round) async {
    final response = await _get('$_baseUrl/$season/$round/results.json');
    final raceTable = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    if (raceTable.isEmpty) return [];
    final resultsJson =
        (raceTable.first as Map<String, dynamic>)['Results'] as List<dynamic>;
    return resultsJson
        .map((r) =>
            RaceResult.fromJolpica(r as Map<String, dynamic>, season, round))
        .toList();
  }

  /// Descarga todos los resultados, recorriendo las paginas de Jolpica.
  Future<List<RaceResult>> getSeasonResults(int season) async {
    final races = await _getSeasonPages(
      '$_baseUrl/$season/results.json',
      rowsKey: 'Results',
    );
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
    final response = await _get('$_baseUrl/$season/$round/qualifying.json');
    final raceTable = _mrData(response)['RaceTable']['Races'] as List<dynamic>;
    if (raceTable.isEmpty) return [];
    final qualiJson = (raceTable.first
        as Map<String, dynamic>)['QualifyingResults'] as List<dynamic>;
    return qualiJson
        .map((q) => QualifyingResult.fromJolpica(
            q as Map<String, dynamic>, season, round))
        .toList();
  }

  /// Descarga toda la clasificacion, recorriendo todas las paginas.
  Future<List<QualifyingResult>> getSeasonQualifying(int season) async {
    final races = await _getSeasonPages(
      '$_baseUrl/$season/qualifying.json',
      rowsKey: 'QualifyingResults',
    );
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
    final response = await _get('$_baseUrl/$season/drivers.json');
    final driversJson =
        _mrData(response)['DriverTable']['Drivers'] as List<dynamic>;
    return driversJson
        .map((d) => Driver.fromJolpica(d as Map<String, dynamic>, ''))
        .toList();
  }

  Future<List<ConstructorTeam>> getConstructors(int season) async {
    final response = await _get('$_baseUrl/$season/constructors.json');
    final json =
        _mrData(response)['ConstructorTable']['Constructors'] as List<dynamic>;
    return json
        .map((c) => ConstructorTeam.fromJolpica(c as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> _getSeasonPages(
    String url, {
    required String rowsKey,
  }) async {
    final allRaces = <dynamic>[];
    var offset = 0;
    while (true) {
      final response = await _get(
        url,
        queryParameters: {'limit': _pageSize, 'offset': offset},
      );
      final mrData = _mrData(response);
      final races = mrData['RaceTable']['Races'] as List<dynamic>? ?? const [];
      allRaces.addAll(races);

      final rowsInPage = races.fold<int>(0, (sum, raceRaw) {
        final race = raceRaw as Map<String, dynamic>;
        return sum + ((race[rowsKey] as List<dynamic>?)?.length ?? 0);
      });
      if (rowsInPage == 0) break;

      offset += rowsInPage;
      final total = int.tryParse(mrData['total']?.toString() ?? '') ?? offset;
      if (offset >= total) break;
    }
    return allRaces;
  }

  Future<Response<Map<String, dynamic>>> _get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final previous = _requestTail;
    final completed = Completer<void>();
    _requestTail = completed.future;
    await previous;
    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        await _paceRequest();
        try {
          return await _dio.get<Map<String, dynamic>>(
            url,
            queryParameters: queryParameters,
          );
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          final retryable = status == 429 ||
              status == 500 ||
              status == 502 ||
              status == 503 ||
              status == 504;
          if (!retryable || attempt == 3) rethrow;
          await Future<void>.delayed(_retryDelay(error, attempt));
        }
      }
      throw StateError('No se pudo completar la peticion a Jolpica');
    } finally {
      completed.complete();
    }
  }

  Future<void> _paceRequest() async {
    final last = _lastRequestStarted;
    if (last != null) {
      final remaining = _minimumRequestGap - DateTime.now().difference(last);
      if (!remaining.isNegative) await Future<void>.delayed(remaining);
    }
    _lastRequestStarted = DateTime.now();
  }

  Duration _retryDelay(DioException error, int attempt) {
    final header = error.response?.headers.value('retry-after');
    final seconds = int.tryParse(header ?? '');
    if (seconds != null) {
      return Duration(seconds: seconds.clamp(1, 30).toInt());
    }
    return Duration(seconds: 2 + attempt);
  }

  Map<String, dynamic> _mrData(Response<Map<String, dynamic>> response) {
    return response.data!['MRData'] as Map<String, dynamic>;
  }
}
