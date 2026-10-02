import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/openf1_api.dart';
import '../domain/models/race.dart';
import 'fantasy_standings_provider.dart';
import 'providers.dart';
import 'selected_gp.dart';

/// Datos del fin de semana en curso (o del finde de un GP pasado) desde
/// OpenF1, agregados por sesión (docs/plans/PLAN_PREDICCION_SESIONES.md).
/// Es lo que hace que la predicción mejore por etapas: pre-finde -> con FP1
/// -> con FP1+FP2 -> con FP1+FP2+FP3. Se detiene antes de clasificación.
class WeekendData {
  const WeekendData({
    this.sessions = const <String>{},
    this.byDriverId = const {},
    this.insights = const {},
    this.error,
  });

  /// Sesiones terminadas con datos: subconjunto de {fp1, fp2, fp3}.
  final Set<String> sessions;

  /// driverId -> { 'onelap:fp1': gap%, 'pace:fp1': gap%, ... }.
  /// Gap % contra el mejor de cada sesión (0 = el más rápido).
  final Map<String, Map<String, double>> byDriverId;

  final Map<String, DriverWeekendInsight> insights;

  /// Error visible (nunca silencioso); si hay error, sessions queda vacío
  /// y la predicción sigue en modo pre-finde.
  final String? error;

  bool get isEmpty => sessions.isEmpty;

  /// Etiqueta de etapa para la UI.
  String get stageLabel {
    if (sessions.isEmpty) return 'PRE-FINDE';
    const order = ['fp1', 'fp2', 'fp3'];
    const labels = {'fp1': 'FP1', 'fp2': 'FP2', 'fp3': 'FP3'};
    final present = order
        .where(sessions.contains)
        .map((s) => labels[s]!)
        .toList();
    return 'CON ${present.join('+')}';
  }
}

class DriverWeekendInsight {
  const DriverWeekendInsight({
    required this.driverId,
    required this.sessionCount,
    required this.totalLaps,
    required this.oneLapGapPercent,
    required this.paceGapPercent,
    required this.longRunSpreadPercent,
  });

  final String driverId;
  final int sessionCount;
  final int totalLaps;
  final double oneLapGapPercent;
  final double paceGapPercent;
  final double longRunSpreadPercent;
}

/// Nombres de país Jolpica -> OpenF1 cuando difieren.
const _countryNameMap = {
  'UK': 'United Kingdom',
  'USA': 'United States',
  'United States': 'United States',
  'UAE': 'United Arab Emirates',
};

String? _sessionKeyOf(String sessionName) {
  switch (sessionName) {
    case 'Practice 1':
      return 'fp1';
    case 'Practice 2':
      return 'fp2';
    case 'Practice 3':
      return 'fp3';
    default:
      return null; // Quali / SQ / Race / Sprint no alimentan la predicción.
  }
}

String _normalize(String text) {
  const accents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const plain = 'aaaaaeeeeiiiiooooouuuunc';
  var out = text.toLowerCase().trim();
  for (var i = 0; i < accents.length; i++) {
    out = out.replaceAll(accents[i], plain[i]);
  }
  return out;
}

/// Agregados del finde para el GP seleccionado. Se cachea en memoria y se
/// refresca con el pull-to-refresh de Pulso (invalidate).
final weekendDataProvider = FutureProvider<WeekendData>((ref) async {
  final race = await ref.watch(selectedRaceProvider.future);
  if (race == null) return const WeekendData();

  // Solo tiene sentido si el finde ya empezó (o el GP es pasado): las
  // sesiones existen desde ~2 días antes de la carrera.
  final now = DateTime.now();
  if (race.date.subtract(const Duration(days: 3)).isAfter(now)) {
    return const WeekendData();
  }

  final api = ref.watch(openF1ApiProvider);
  try {
    final catalog = await ref.watch(fantasyAssetNameProvider.future);
    return await loadWeekendData(
      api: api,
      race: race,
      now: now,
      catalog: catalog,
    );
  } catch (e) {
    return WeekendData(
      error:
          'OpenF1 no pudo cargar ${race.raceName}: '
          '${_describeOpenF1Error(e)}. Predicción en modo pre-finde.',
    );
  }
});

/// Separa la descarga de OpenF1 del provider para probar selección de sesión,
/// correspondencia de pilotos y degradación cuando falla una sesión.
Future<WeekendData> loadWeekendData({
  required OpenF1Api api,
  required Race race,
  required DateTime now,
  required Map<String, FantasyAssetInfo> catalog,
}) async {
  final countryName = _countryNameMap[race.country] ?? race.country;
  final sessions = await api.getSessions(
    year: race.season,
    countryName: countryName,
  );

  // Filtrar al meeting correcto por fecha (España tiene 2 GPs en 2026) y
  // quedarnos con las sesiones terminadas que alimentan la predicción.
  final windowStart = race.date.subtract(const Duration(days: 5));
  final completed = <String, int>{}; // sessionKey lógico -> session_key OpenF1
  for (final s in sessions) {
    final key = _sessionKeyOf(s['session_name']?.toString() ?? '');
    if (key == null) continue;
    final start = DateTime.tryParse(s['date_start']?.toString() ?? '');
    final end = DateTime.tryParse(s['date_end']?.toString() ?? '');
    if (start == null || end == null) continue;
    if (start.isBefore(windowStart) || start.isAfter(race.date)) continue;
    if (end.isAfter(now)) continue; // aún no terminada
    completed[key] = (s['session_key'] as num).toInt();
  }
  if (completed.isEmpty) return const WeekendData();

  // Mapa dorsal -> driverId usando los nombres del catálogo.
  final driverNames = <String, String>{
    for (final e in catalog.entries)
      if (e.value.kind == FantasyAssetKind.driver)
        e.key: _normalize(e.value.name),
  };
  List<Map<String, dynamic>> openF1Drivers = const [];
  final driverLookupErrors = <String>[];
  for (final session in completed.entries.toList().reversed) {
    try {
      openF1Drivers = await api.getSessionDrivers(session.value);
      if (openF1Drivers.isNotEmpty) break;
    } catch (error) {
      // Prueba otra sesión del mismo meeting por si ese key no está publicado.
      driverLookupErrors.add(
        '${session.key.toUpperCase()} (${_describeOpenF1Error(error)})',
      );
    }
  }
  final numberToDriverId = <String, String>{};
  for (final d in openF1Drivers) {
    final number = d['driver_number']?.toString();
    final lastName = _normalize(d['last_name']?.toString() ?? '');
    final fullName = _normalize(d['full_name']?.toString() ?? '');
    if (number == null || lastName.isEmpty) continue;
    for (final entry in driverNames.entries) {
      if (_matchesDriverName(entry.value, lastName, fullName)) {
        numberToDriverId[number] = entry.key;
        break;
      }
    }
  }

  // Descargar vueltas de cada sesión terminada y convertir a gaps %.
  final byDriverId = <String, Map<String, double>>{};
  final insightBuilders = <String, _InsightBuilder>{};
  final withData = <String>{};
  final failedSessions = <String>[];
  final emptySessions = <String>[];
  var hasAggregates = false;
  var hasMappedDrivers = false;
  for (final entry in completed.entries) {
    List<Map<String, dynamic>> laps;
    try {
      laps = await api.getLaps(entry.value);
    } catch (error) {
      // Una respuesta ausente para FP2/FP3 no invalida vueltas ya recibidas
      // en FP1. Se conserva la etapa parcial y se indica el dato faltante.
      failedSessions.add(_sessionFailureLabel(entry.key, error));
      continue;
    }
    final aggregates = api.aggregateStints(
      laps: laps,
      season: race.season,
      round: race.round,
      sessionKey: entry.key,
    );
    if (aggregates.isEmpty) {
      emptySessions.add(entry.key.toUpperCase());
      continue;
    }
    hasAggregates = true;

    double bestLap = double.infinity;
    double bestPace = double.infinity;
    for (final a in aggregates.values) {
      if (a.bestLapMs < bestLap) bestLap = a.bestLapMs;
      if (a.top2StintsAvgMs < bestPace) bestPace = a.top2StintsAvgMs;
    }
    if (bestLap <= 0 || bestLap.isInfinite) continue;
    aggregates.forEach((driverNumber, a) {
      final driverId = numberToDriverId[driverNumber];
      if (driverId == null) return;
      hasMappedDrivers = true;
      final map = byDriverId.putIfAbsent(driverId, () => <String, double>{});
      map['onelap:${entry.key}'] = (a.bestLapMs - bestLap) / bestLap * 100.0;
      map['pace:${entry.key}'] =
          (a.top2StintsAvgMs - bestPace) / bestPace * 100.0;
      final insight = insightBuilders.putIfAbsent(
        driverId,
        () => _InsightBuilder(driverId),
      );
      insight.sessionCount++;
      insight.totalLaps += a.lapCount;
      insight.oneLapGapPercent = map['onelap:${entry.key}']!;
      insight.paceGapPercent = map['pace:${entry.key}']!;
      insight.spreads.add(
        (a.top2StintsAvgMs - a.bestLapMs) / a.bestLapMs * 100,
      );
    });
    if (aggregates.keys.any(numberToDriverId.containsKey)) {
      withData.add(entry.key);
    }
  }

  return WeekendData(
    sessions: withData,
    byDriverId: byDriverId,
    error: hasAggregates && !hasMappedDrivers
        ? 'OpenF1 no pudo asociar las vueltas de ${race.raceName} '
              'a los pilotos del catálogo'
              '${driverLookupErrors.isEmpty ? '.' : ': ${driverLookupErrors.join(', ')}.'}'
        : (failedSessions.isEmpty && emptySessions.isEmpty
              ? null
              : 'OpenF1 no devolvió datos de '
                    '${[...failedSessions, ...emptySessions].join(', ')} '
                    'para ${race.raceName}; se usan las sesiones disponibles.'),
    insights: {
      for (final entry in insightBuilders.entries)
        entry.key: entry.value.build(),
    },
  );
}

String _sessionFailureLabel(String sessionKey, Object error) =>
    '${sessionKey.toUpperCase()} (${_describeOpenF1Error(error)})';

String _describeOpenF1Error(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final path = error.requestOptions.uri.path;
    if (status != null) return 'HTTP $status en $path';
    final message = error.message;
    if (message != null && message.isNotEmpty) return message;
    return error.type.name;
  }
  return error.toString().split('\n').first;
}

bool _matchesDriverName(String catalogName, String lastName, String fullName) {
  if (catalogName == fullName) return true;
  final catalogTokens = catalogName.split(RegExp(r'[^a-z0-9]+'))
    ..removeWhere((token) => token.isEmpty);
  final surnameTokens = lastName.split(RegExp(r'[^a-z0-9]+'))
    ..removeWhere((token) => token.isEmpty);
  if (surnameTokens.isEmpty || surnameTokens.length > catalogTokens.length) {
    return false;
  }
  final suffix = catalogTokens.sublist(
    catalogTokens.length - surnameTokens.length,
  );
  return List.generate(
    surnameTokens.length,
    (i) => suffix[i] == surnameTokens[i],
  ).every((matches) => matches);
}

class _InsightBuilder {
  _InsightBuilder(this.driverId);

  final String driverId;
  int sessionCount = 0;
  int totalLaps = 0;
  double oneLapGapPercent = 0;
  double paceGapPercent = 0;
  final List<double> spreads = [];

  DriverWeekendInsight build() => DriverWeekendInsight(
    driverId: driverId,
    sessionCount: sessionCount,
    totalLaps: totalLaps,
    oneLapGapPercent: oneLapGapPercent,
    paceGapPercent: paceGapPercent,
    longRunSpreadPercent: spreads.isEmpty
        ? 0
        : spreads.reduce((a, b) => a + b) / spreads.length,
  );
}
