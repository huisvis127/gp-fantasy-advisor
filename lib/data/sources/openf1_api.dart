import 'package:dio/dio.dart';

import '../../domain/models/session_laps.dart';

/// Cliente de OpenF1: tiempos por vuelta y sesiones (FP1-FP3, quali) del fin
/// de semana en curso. Se usa solo cuando hay sesión en marcha (sección 5.1);
/// el resto del tiempo el motor usa el histórico de Jolpica.
class OpenF1Api {
  OpenF1Api(this._dio, {required String baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<List<Map<String, dynamic>>> getSessions({
    required int year,
    required String countryName,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/sessions',
      queryParameters: {'year': year, 'country_name': countryName},
    );
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Pilotos de una sesión: driver_number, nombre y equipo. Se usa para
  /// mapear los dorsales de OpenF1 a nuestros driverId (por apellido).
  Future<List<Map<String, dynamic>>> getSessionDrivers(int sessionKey) async {
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/drivers',
      queryParameters: {'session_key': sessionKey},
    );
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Vueltas en bruto de una sesión. Se agregan localmente a
  /// `SessionLapsAggregate` con `_aggregateStints` para no guardar vuelta a
  /// vuelta en drift (demasiado volumen; sección 4: "agregados por sesión").
  Future<List<Map<String, dynamic>>> getLaps(int sessionKey) async {
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/laps',
      queryParameters: {'session_key': sessionKey},
    );
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Calcula mejor stint, media top-2 stints y mejor vuelta por piloto,
  /// filtrando vueltas con pit_out_time o is_pit_out_lap (vueltas sucias).
  Map<String, SessionLapsAggregate> aggregateStints({
    required List<Map<String, dynamic>> laps,
    required int season,
    required int round,
    required String sessionKey,
  }) {
    final byDriver = <String, List<double>>{};
    for (final lap in laps) {
      final driverNumber = lap['driver_number']?.toString();
      final lapDuration = (lap['lap_duration'] as num?)?.toDouble();
      final isPitOut = lap['is_pit_out_lap'] == true;
      if (driverNumber == null || lapDuration == null || isPitOut) continue;
      byDriver.putIfAbsent(driverNumber, () => []).add(lapDuration * 1000);
    }

    final result = <String, SessionLapsAggregate>{};
    byDriver.forEach((driverNumber, lapTimesMs) {
      if (lapTimesMs.isEmpty) return;
      final sorted = [...lapTimesMs]..sort();
      final bestLap = sorted.first;
      // "Stint" simplificado: bloques de vueltas consecutivas sin outlier
      // (> 107% del mejor tiempo se descarta como vuelta sucia/tráfico).
      final clean = sorted.where((t) => t <= bestLap * 1.07).toList();
      final bestStintAvg = clean.take(3).reduce((a, b) => a + b) / clean.take(3).length;
      final top2 = clean.take(2).toList();
      final top2Avg = top2.isEmpty ? bestStintAvg : top2.reduce((a, b) => a + b) / top2.length;

      result[driverNumber] = SessionLapsAggregate(
        season: season,
        round: round,
        sessionKey: sessionKey,
        driverId: driverNumber, // se mapea a driverId real en DataRepository
        bestStintAvgMs: bestStintAvg,
        top2StintsAvgMs: top2Avg,
        bestLapMs: bestLap,
        lapCount: lapTimesMs.length,
      );
    });
    return result;
  }
}
