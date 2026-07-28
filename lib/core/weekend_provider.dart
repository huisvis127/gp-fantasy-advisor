import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/openf1_api.dart';
import '../domain/models/race.dart';
import 'fantasy_standings_provider.dart';
import 'providers.dart';
import 'selected_gp.dart';

enum PredictionDataWindow { preWeekend, friday, saturday }

extension PredictionDataWindowLabel on PredictionDataWindow {
  String get shortLabel => switch (this) {
        PredictionDataWindow.preWeekend => 'Pre-finde',
        PredictionDataWindow.friday => 'Viernes',
        PredictionDataWindow.saturday => 'Viernes + sáb.',
      };
}

class PredictionDataWindowNotifier extends Notifier<PredictionDataWindow?> {
  @override
  PredictionDataWindow? build() {
    // Cada GP empieza en automático: se usa la última ventana disponible.
    ref.watch(selectedSeasonProvider);
    ref.watch(selectedRoundProvider);
    return null;
  }

  void select(PredictionDataWindow window) => state = window;
  void useLatestAvailable() => state = null;
}

final predictionDataWindowProvider =
    NotifierProvider<PredictionDataWindowNotifier, PredictionDataWindow?>(
  PredictionDataWindowNotifier.new,
);

/// Datos de libres del fin de semana en curso desde OpenF1.
/// La predicción tiene tres ventanas pre-clasificación: histórico, viernes
/// (FP1+FP2) y viernes+sábados (FP1+FP2+FP3).
class WeekendData {
  const WeekendData({
    this.sessions = const <String>{},
    this.byDriverId = const {},
    this.error,
    this.isSprintWeekend = false,
  });

  /// Sesiones terminadas con datos: subconjunto de {fp1, fp2, fp3}.
  final Set<String> sessions;

  /// driverId -> { 'onelap:fp1': gap%, 'pace:fp1': gap%, ... }.
  /// Gap % contra el mejor de cada sesión (0 = el más rápido).
  final Map<String, Map<String, double>> byDriverId;

  /// Error visible (nunca silencioso); si hay error, sessions queda vacío
  /// y la predicción sigue en modo pre-finde.
  final String? error;
  final bool isSprintWeekend;

  bool get isEmpty => sessions.isEmpty;

  PredictionDataWindow get latestAvailableWindow {
    if (!isSprintWeekend && sessions.contains('fp3')) {
      return PredictionDataWindow.saturday;
    }
    if (sessions.contains('fp1') || sessions.contains('fp2')) {
      return PredictionDataWindow.friday;
    }
    return PredictionDataWindow.preWeekend;
  }

  bool isWindowAvailable(PredictionDataWindow window) => switch (window) {
        PredictionDataWindow.preWeekend => true,
        PredictionDataWindow.friday =>
          sessions.contains('fp1') || sessions.contains('fp2'),
        PredictionDataWindow.saturday =>
          !isSprintWeekend && sessions.contains('fp3'),
      };

  PredictionDataWindow resolveWindow(PredictionDataWindow? requested) {
    if (requested == null) return latestAvailableWindow;
    return isWindowAvailable(requested) ? requested : latestAvailableWindow;
  }

  Set<String> sessionsFor(PredictionDataWindow window) {
    final allowed = switch (window) {
      PredictionDataWindow.preWeekend => const <String>{},
      PredictionDataWindow.friday => const {'fp1', 'fp2'},
      PredictionDataWindow.saturday => const {'fp1', 'fp2', 'fp3'},
    };
    return sessions.where(allowed.contains).toSet();
  }

  Map<String, Map<String, double>> byDriverIdFor(
    PredictionDataWindow window,
  ) {
    final allowed = sessionsFor(window);
    if (allowed.isEmpty) return const {};
    return {
      for (final driver in byDriverId.entries)
        driver.key: {
          for (final metric in driver.value.entries)
            if (allowed.contains(metric.key.split(':').last))
              metric.key: metric.value,
        },
    };
  }

  String labelFor(PredictionDataWindow window) {
    final selectedSessions = sessionsFor(window);
    if (selectedSessions.isEmpty) return 'PRE-FINDE';
    const order = ['fp1', 'fp2', 'fp3'];
    const labels = {
      'fp1': 'FP1',
      'fp2': 'FP2',
      'fp3': 'FP3',
    };
    final present =
        order.where(selectedSessions.contains).map((s) => labels[s]!).toList();
    return 'CON ${present.join('+')}';
  }

  String get stageLabel => labelFor(latestAvailableWindow);
}

/// Nombres de país Jolpica -> OpenF1 cuando difieren.
const _countryNameMap = {
  'UK': 'United Kingdom',
  'USA': 'United States',
  'United States': 'United States',
  'UAE': 'United Arab Emirates',
};

String? practiceSessionKeyOf(String sessionName) {
  switch (sessionName) {
    case 'Practice 1':
      return 'fp1';
    case 'Practice 2':
      return 'fp2';
    case 'Practice 3':
      return 'fp3';
    default:
      // Race, Sprint, Qualifying y Sprint Qualifying nunca alimentan una
      // recomendación que debe estar lista antes del cierre de Fantasy.
      return null;
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

  final now = DateTime.now();
  if (!shouldLoadWeekendData(race, now)) {
    return const WeekendData();
  }

  final api = ref.watch(openF1ApiProvider);
  try {
    return await _loadWeekend(api, ref, race, now);
  } catch (e) {
    return WeekendData(
      error: 'OpenF1 no respondió (${e.toString().split('\n').first}). '
          'Predicción en modo pre-finde.',
      isSprintWeekend: race.hasSprint,
    );
  }
});

/// OpenF1 solo debe consultarse durante el fin de semana seleccionado.
///
/// Además de evitar ráfagas de peticiones al navegar por carreras anteriores,
/// impide que un backtest incorpore datos del propio fin de semana que todavía
/// no existían cuando se habría tomado la decisión.
bool shouldLoadWeekendData(Race race, DateTime now) {
  return !race.date.subtract(const Duration(days: 3)).isAfter(now);
}

Future<WeekendData> _loadWeekend(
  OpenF1Api api,
  Ref ref,
  Race race,
  DateTime now,
) async {
  final countryName = _countryNameMap[race.country] ?? race.country;
  final sessions =
      await api.getSessions(year: race.season, countryName: countryName);

  // Filtrar al meeting correcto por fecha (España tiene 2 GPs en 2026) y
  // quedarnos con las sesiones terminadas que alimentan la predicción.
  final windowStart = race.date.subtract(const Duration(days: 5));
  final completed = <String, int>{}; // sessionKey lógico -> session_key OpenF1
  int? latestCompletedSessionKey;
  DateTime? latestCompletedEnd;
  for (final s in sessions) {
    final key = practiceSessionKeyOf(s['session_name']?.toString() ?? '');
    if (key == null) continue;
    final start = DateTime.tryParse(s['date_start']?.toString() ?? '');
    final end = DateTime.tryParse(s['date_end']?.toString() ?? '');
    if (start == null || end == null) continue;
    if (start.isBefore(windowStart) || start.isAfter(race.date)) continue;
    if (end.isAfter(now)) continue; // aún no terminada
    final openF1SessionKey = (s['session_key'] as num).toInt();
    completed[key] = openF1SessionKey;
    if (latestCompletedEnd == null || end.isAfter(latestCompletedEnd)) {
      latestCompletedEnd = end;
      latestCompletedSessionKey = openF1SessionKey;
    }
  }
  if (completed.isEmpty) {
    return WeekendData(isSprintWeekend: race.hasSprint);
  }

  // Mapa dorsal -> driverId usando los nombres del catálogo.
  final catalog = await ref.watch(fantasyAssetNameProvider.future);
  final driverNames = <String, String>{
    for (final e in catalog.entries)
      if (e.value.kind == FantasyAssetKind.driver)
        e.key: _normalize(e.value.name),
  };
  final openF1Drivers = await api.getSessionDrivers(
    latestCompletedSessionKey ?? completed.values.first,
  );
  final numberToDriverId = <String, String>{};
  for (final d in openF1Drivers) {
    final number = d['driver_number']?.toString();
    final lastName = _normalize(d['last_name']?.toString() ?? '');
    final fullName = _normalize(d['full_name']?.toString() ?? '');
    if (number == null || lastName.isEmpty) continue;
    for (final entry in driverNames.entries) {
      if (entry.value.contains(lastName) || fullName.contains(entry.value)) {
        numberToDriverId[number] = entry.key;
        break;
      }
    }
  }

  // Descargar vueltas de cada sesión terminada y convertir a gaps %.
  final byDriverId = <String, Map<String, double>>{};
  final withData = <String>{};
  for (final entry in completed.entries) {
    final laps = await api.getLaps(entry.value);
    final aggregates = api.aggregateStints(
      laps: laps,
      season: race.season,
      round: race.round,
      sessionKey: entry.key,
    );
    if (aggregates.isEmpty) continue;

    double bestLap = double.infinity;
    double bestPace = double.infinity;
    for (final a in aggregates.values) {
      if (a.bestLapMs < bestLap) bestLap = a.bestLapMs;
      if (a.top2StintsAvgMs < bestPace) bestPace = a.top2StintsAvgMs;
    }
    if (bestLap <= 0 || bestLap.isInfinite) continue;
    withData.add(entry.key);

    aggregates.forEach((driverNumber, a) {
      final driverId = numberToDriverId[driverNumber];
      if (driverId == null) return;
      final map = byDriverId.putIfAbsent(driverId, () => <String, double>{});
      map['onelap:${entry.key}'] = (a.bestLapMs - bestLap) / bestLap * 100.0;
      map['pace:${entry.key}'] =
          (a.top2StintsAvgMs - bestPace) / bestPace * 100.0;
    });
  }

  return WeekendData(
    sessions: withData,
    byDriverId: byDriverId,
    isSprintWeekend: race.hasSprint,
  );
}
