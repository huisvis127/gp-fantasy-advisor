import 'dart:async';

import 'package:dio/dio.dart';

import '../../domain/models/session_laps.dart';

/// Cliente de OpenF1: tiempos por vuelta de libres (FP1-FP3) del fin
/// de semana en curso. Se usa solo cuando hay sesión en marcha (sección 5.1);
/// el resto del tiempo el motor usa el histórico de Jolpica.
class OpenF1Api {
  OpenF1Api(
    this._dio, {
    required String baseUrl,
    Duration minimumRequestGap = const Duration(milliseconds: 350),
    Duration retryBaseDelay = const Duration(seconds: 2),
  })  : _baseUrl = baseUrl,
        _minimumRequestGap = minimumRequestGap,
        _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final String _baseUrl;
  final Duration _minimumRequestGap;
  final Duration _retryBaseDelay;
  Future<void> _requestTail = Future.value();
  DateTime? _lastRequestStarted;
  final Map<int, List<Map<String, dynamic>>> _driverCache = {};
  final Map<int, List<Map<String, dynamic>>> _lapCache = {};
  final Map<String, ({DateTime at, List<Map<String, dynamic>> rows})>
      _sessionCache = {};

  Future<List<Map<String, dynamic>>> getSessions({
    required int year,
    required String countryName,
  }) async {
    final cacheKey = '$year:$countryName';
    final cached = _sessionCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(seconds: 30)) {
      return cached.rows;
    }
    final rows = await _getList(
      '$_baseUrl/sessions',
      queryParameters: {'year': year, 'country_name': countryName},
    );
    _sessionCache[cacheKey] = (at: DateTime.now(), rows: rows);
    return rows;
  }

  /// Pilotos de una sesión: driver_number, nombre y equipo. Se usa para
  /// mapear los dorsales de OpenF1 a nuestros driverId (por apellido).
  Future<List<Map<String, dynamic>>> getSessionDrivers(int sessionKey) async {
    final cached = _driverCache[sessionKey];
    if (cached != null) return cached;
    final rows = await _getList(
      '$_baseUrl/drivers',
      queryParameters: {'session_key': sessionKey},
    );
    _driverCache[sessionKey] = rows;
    return rows;
  }

  /// Vueltas en bruto de una sesión. Se agregan localmente a
  /// `SessionLapsAggregate` con `_aggregateStints` para no guardar vuelta a
  /// vuelta en drift (demasiado volumen; sección 4: "agregados por sesión").
  Future<List<Map<String, dynamic>>> getLaps(int sessionKey) async {
    final cached = _lapCache[sessionKey];
    if (cached != null) return cached;
    final rows = await _getList(
      '$_baseUrl/laps',
      queryParameters: {'session_key': sessionKey},
    );
    _lapCache[sessionKey] = rows;
    return rows;
  }

  Future<List<Map<String, dynamic>>> _getList(
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
          final response = await _dio.get<List<dynamic>>(
            url,
            queryParameters: queryParameters,
          );
          return (response.data ?? []).cast<Map<String, dynamic>>();
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          final retryable = status == 429 ||
              status == 500 ||
              status == 502 ||
              status == 503 ||
              status == 504 ||
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout;
          if (!retryable || attempt == 3) rethrow;
          await Future<void>.delayed(_retryDelay(error, attempt));
        }
      }
      throw StateError('No se pudo completar la petición a OpenF1');
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
    final retryAfter = error.response?.headers.value('retry-after');
    final seconds = int.tryParse(retryAfter ?? '');
    if (seconds != null) {
      return Duration(seconds: seconds.clamp(1, 30).toInt());
    }
    return _retryBaseDelay * (attempt + 1);
  }

  /// Calcula mejor vuelta y ritmo de tandas reales por piloto. Una tanda
  /// requiere al menos 3 vueltas limpias consecutivas; cooldowns, pit-out y
  /// vueltas por encima del 107% cortan la secuencia.
  Map<String, SessionLapsAggregate> aggregateStints({
    required List<Map<String, dynamic>> laps,
    required int season,
    required int round,
    required String sessionKey,
  }) {
    final byDriver =
        <String, List<({int lapNumber, double durationMs, bool isPitOut})>>{};
    for (final lap in laps) {
      final driverNumber = lap['driver_number']?.toString();
      final lapDuration = (lap['lap_duration'] as num?)?.toDouble();
      final lapNumber = (lap['lap_number'] as num?)?.toInt();
      final isPitOut = lap['is_pit_out_lap'] == true;
      if (driverNumber == null ||
          lapDuration == null ||
          lapDuration <= 0 ||
          lapNumber == null) {
        continue;
      }
      byDriver.putIfAbsent(driverNumber, () => []).add(
        (
          lapNumber: lapNumber,
          durationMs: lapDuration * 1000,
          isPitOut: isPitOut,
        ),
      );
    }

    final result = <String, SessionLapsAggregate>{};
    byDriver.forEach((driverNumber, rows) {
      final validRows = rows.where((row) => !row.isPitOut).toList();
      if (validRows.isEmpty) return;
      validRows.sort((a, b) => a.lapNumber.compareTo(b.lapNumber));
      final bestLap = validRows
          .map((row) => row.durationMs)
          .reduce((a, b) => a < b ? a : b);
      final cleanLimit = bestLap * 1.07;
      final stintAverages = <double>[];
      var current = <double>[];
      int? previousLap;

      void closeStint() {
        if (current.length >= 3) {
          stintAverages.add(
            current.reduce((a, b) => a + b) / current.length,
          );
        }
        current = <double>[];
      }

      for (final row in rows.where((row) => !row.isPitOut).toList()
        ..sort((a, b) => a.lapNumber.compareTo(b.lapNumber))) {
        final consecutive =
            previousLap == null || row.lapNumber == previousLap + 1;
        final clean = row.durationMs <= cleanLimit;
        if (!consecutive || !clean) closeStint();
        if (clean) current.add(row.durationMs);
        previousLap = row.lapNumber;
      }
      closeStint();

      final cleanTimes = validRows
          .where((row) => row.durationMs <= cleanLimit)
          .map((row) => row.durationMs)
          .toList()
        ..sort();
      if (cleanTimes.isEmpty) return;
      // Respaldo cuando el programa de libres no contiene 3 vueltas
      // consecutivas: media de hasta las 5 vueltas limpias más rápidas.
      if (stintAverages.isEmpty) {
        final fallback = cleanTimes.take(5).toList();
        stintAverages.add(
          fallback.reduce((a, b) => a + b) / fallback.length,
        );
      }
      stintAverages.sort();
      final bestStintAvg = stintAverages.first;
      final top2 = stintAverages.take(2).toList();
      final top2Avg = top2.reduce((a, b) => a + b) / top2.length;

      result[driverNumber] = SessionLapsAggregate(
        season: season,
        round: round,
        sessionKey: sessionKey,
        driverId: driverNumber, // se mapea a driverId real en DataRepository
        bestStintAvgMs: bestStintAvg,
        top2StintsAvgMs: top2Avg,
        bestLapMs: bestLap,
        lapCount: validRows.length,
      );
    });
    return result;
  }
}
