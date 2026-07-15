import 'package:drift/drift.dart' show Value;

import '../../domain/engine/driver_context.dart';
import '../../domain/models/my_team.dart';
import '../../domain/models/qualifying_result.dart';
import '../../domain/models/race.dart';
import '../../domain/models/race_result.dart';
import '../db/database.dart';
import '../sources/fantasy_api.dart';
import '../sources/jolpica_api.dart';
import '../sources/openf1_api.dart';

/// Informe de la última sincronización: qué se descargó y qué falló.
/// La UI lo muestra siempre (nada de fallos silenciosos).
class SyncReport {
  SyncReport();

  int racesSynced = 0;
  int resultsSynced = 0;
  int pricesSynced = 0;
  final List<String> errors = [];

  bool get isEmpty =>
      racesSynced == 0 && resultsSynced == 0 && pricesSynced == 0;
}

/// Puerta única entre la UI y los datos (sección 3 del plan). Política
/// stale-while-revalidate: se devuelve la caché al instante y se refresca
/// en segundo plano. La app debe funcionar 100% en modo lectura sin conexión
/// con los últimos datos cacheados.
class DataRepository {
  DataRepository({
    required AppDatabase db,
    required JolpicaApi jolpica,
    required OpenF1Api openF1,
    required FantasyApi fantasyApi,
  })  : _db = db,
        _jolpica = jolpica,
        _openF1 = openF1,
        _fantasyApi = fantasyApi;

  final AppDatabase _db;
  final JolpicaApi _jolpica;
  // ignore: unused_field
  final OpenF1Api _openF1;
  final FantasyApi _fantasyApi;

  /// Sincronización inicial (Fase 1, criterio de aceptación): calendario del
  /// año en curso, resultados de la temporada, 2 temporadas históricas y
  /// precios fantasy actuales. Se llama al abrir la app si hay red; los
  /// fallos individuales no deben interrumpir el resto de la sync.
  Future<SyncReport> syncAll({required int currentSeason}) async {
    final report = SyncReport();
    // Prioriza la temporada actual: el calendario visible no debe depender
    // de que terminen primero todas las descargas históricas.
    final seasonsToSync = [currentSeason, currentSeason - 1, currentSeason - 2];
    for (final season in seasonsToSync) {
      await _trySync(report, 'temporada $season',
          () => _syncCalendarAndResults(season, report));
    }
    await _trySync(
        report, 'precios fantasy', () => _syncPrices(currentSeason, report));
    return report;
  }

  Future<void> _trySync(
      SyncReport report, String label, Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      // Fallo de red o de un endpoint puntual: se mantiene la caché existente
      // y se informa a la UI a través del SyncReport.
      report.errors.add('$label: ${_shortError(e)}');
    }
  }

  String _shortError(Object e) {
    final text = e.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  Future<void> _syncCalendarAndResults(int season, SyncReport report) async {
    final calendar = await _jolpica.getSeasonCalendar(season);
    await _db.upsertRaces(calendar.map(_raceToCompanion).toList());
    report.racesSynced += calendar.length;

    final drivers = await _jolpica.getDrivers(season);
    await _db.upsertDrivers(drivers
        .map((d) => DriversCompanion.insert(
              id: d.id,
              code: d.code,
              givenName: d.givenName,
              familyName: d.familyName,
              constructorId: d.constructorId,
              number: Value(d.number),
            ))
        .toList());

    final constructorsList = await _jolpica.getConstructors(season);
    await _db.upsertConstructors(constructorsList
        .map((c) => ConstructorsCompanion.insert(
              id: c.id,
              name: c.name,
              nationality: c.nationality,
            ))
        .toList());

    // Descargas agrupadas: resultados y clasificación requieren una sola
    // petición cada uno, en lugar de dos peticiones por ronda.
    final raceResults = await _jolpica.getSeasonResults(season);
    if (raceResults.isNotEmpty) {
      await _db.upsertResults(raceResults.map(_resultToCompanion).toList());
      report.resultsSynced += raceResults.length;
    }

    final qualifying = await _jolpica.getSeasonQualifying(season);
    if (qualifying.isNotEmpty) {
      await _db.upsertQualifying(qualifying.map(_qualiToCompanion).toList());
    }

    // Jolpica no da el constructorId en /drivers.json. Se completa con el
    // resultado más reciente de cada piloto.
    final latestConstructorByDriver = <String, String>{};
    for (final result in raceResults) {
      latestConstructorByDriver[result.driverId] = result.constructorId;
    }

    if (latestConstructorByDriver.isNotEmpty) {
      await _db.updateDriverConstructors(latestConstructorByDriver);
    }
  }

  Future<void> _syncPrices(int season, SyncReport report) async {
    final prices = await _fantasyApi.getCurrentPrices(season);
    report.pricesSynced += prices.length;
    await _db.upsertPrices(prices
        .map((p) => FantasyPricesCompanion.insert(
              assetId: p.assetId,
              assetType: p.assetType.name,
              season: p.season,
              round: p.round,
              priceMillions: p.priceMillions,
            ))
        .toList());
  }

  // ---- Lecturas (siempre desde caché local; instantáneas) ----

  Future<Race?> nextRace(int season) async {
    final row = await _db.nextRace(season, DateTime.now());
    return row == null ? null : _raceRowToDomain(row);
  }

  Future<List<Race>> allRaces(int season) async {
    final rows = await _db.allRaces(season);
    return rows.map(_raceRowToDomain).toList();
  }

  Future<double?> currentPrice(String assetId, {required bool isConstructor}) =>
      _db.latestPrice(assetId, isConstructor ? 'constructor' : 'driver');

  /// ¿Hay precios reales de la API de F1 Fantasy en caché? Si no, la UI
  /// usa los precios estimados (y lo indica con un aviso).
  Future<bool> hasRealPrices() => _db.hasAnyPrices();

  /// Construye el contexto de features de todos los pilotos (sección 5.1)
  /// para el GP indicado, usando SOLO datos anteriores a ese GP. Así el
  /// selector de carrera funciona también para GPs pasados (modo backtest).
  Future<List<DriverContext>> buildDriverContexts(Race race) async {
    final cutSeason = race.season;
    final cutRound = race.round;

    // Parrilla: pilotos con resultados en la temporada del GP; si aún no
    // hay (principio de temporada), los de la temporada anterior.
    var roster = await _db.driverIdsWithResultsInSeason(cutSeason);
    if (roster.isEmpty) {
      roster = await _db.driverIdsWithResultsInSeason(cutSeason - 1);
    }
    final driverRows = (await _db.allDrivers())
        .where((d) => roster.isEmpty || roster.contains(d.id))
        .toList();
    final gridSize = driverRows.isEmpty ? 20 : driverRows.length;
    const raceScoreByPosition = {
      1: 25,
      2: 18,
      3: 15,
      4: 12,
      5: 10,
      6: 8,
      7: 6,
      8: 4,
      9: 2,
      10: 1,
    };

    final contexts = <DriverContext>[];
    for (final driver in driverRows) {
      final recent8 = await _db.resultsForDriver(
        driver.id,
        limit: 8,
        beforeSeason: cutSeason,
        beforeRound: cutRound,
      );
      final recentQuali = await _db.qualifyingForDriver(
        driver.id,
        limit: 8,
        beforeSeason: cutSeason,
        beforeRound: cutRound,
      );
      final circuitHistory = await _db.resultsForDriverAtCircuit(
        driver.id,
        race.circuitId,
        limit: 4,
        beforeSeason: cutSeason,
        beforeRound: cutRound,
      );

      // Constructor vigente en el momento del corte (el del resultado más
      // reciente antes del GP), no el último conocido globalmente.
      final constructorId = recent8.isNotEmpty
          ? recent8.first.constructorId
          : driver.constructorId;
      final constructorRecent = await _db.resultsForConstructor(
        constructorId,
        limit: 6,
        beforeSeason: cutSeason,
        beforeRound: cutRound,
      );

      final dnfCount = recent8.where((r) => r.finishPosition == null).length;

      contexts.add(DriverContext(
        driverId: driver.id,
        constructorId: constructorId,
        // Se pasan las 8 (no solo 5): la feature de ritmo reciente usa solo
        // las 5 más recientes internamente (take(5)) y la de consistencia
        // usa las 8 (sección 5.1); DriverContext lleva la ventana más ancha.
        recentRaceFinishPositions:
            recent8.map((r) => r.finishPosition).toList(),
        recentQualifyingPositions: recentQuali.map((q) => q.position).toList(),
        // Aproximación sin OpenF1: 0 si tuvo la vuelta rápida, 1.5% si no.
        // Sustituir por el gap real de OpenF1 cuando haya sesión en curso.
        recentFastestLapGapPercent:
            recent8.map((r) => r.fastestLap ? 0.0 : 1.5).toList(),
        circuitHistoryFinishPositions:
            circuitHistory.map((r) => r.finishPosition).toList(),
        constructorRecentPoints: constructorRecent
            .map((r) => (raceScoreByPosition[r.finishPosition] ?? 0).toDouble())
            .toList(),
        driverDnfRateLast2Seasons:
            recent8.isEmpty ? 0.1 : dnfCount / recent8.length,
        constructorDnfRateLast2Seasons:
            0.1, // placeholder hasta agregarlo por constructor
        gridSize: gridSize,
      ));
    }
    return contexts;
  }

  // ---- Mi equipo ----

  Future<void> saveMyTeam(MyTeam team) async {
    await _db.saveMyTeam(MyTeamTableCompanion.insert(
      driverIdsCsv: team.driverIds.join(','),
      constructorIdsCsv: team.constructorIds.join(','),
      remainingBudgetMillions: team.remainingBudgetMillions,
      boostedDriverId: Value(team.boostedDriverId),
      source: team.source.name,
      chipsUsedCsv: Value(team.chipsUsed.join(',')),
    ));
  }

  Future<MyTeam?> loadMyTeam() async {
    final row = await _db.loadMyTeam();
    if (row == null) return null;
    return MyTeam(
      driverIds:
          row.driverIdsCsv.split(',').where((s) => s.isNotEmpty).toList(),
      constructorIds:
          row.constructorIdsCsv.split(',').where((s) => s.isNotEmpty).toList(),
      remainingBudgetMillions: row.remainingBudgetMillions,
      boostedDriverId: row.boostedDriverId,
      source: MyTeamSource.values.firstWhere(
        (s) => s.name == row.source,
        orElse: () => MyTeamSource.manual,
      ),
      chipsUsed: row.chipsUsedCsv.split(',').where((s) => s.isNotEmpty).toSet(),
    );
  }

  // ---- Mappers dominio <-> companions/rows drift ----

  Race _raceRowToDomain(RaceRow r) => Race(
        season: r.season,
        round: r.round,
        raceName: r.raceName,
        circuitId: r.circuitId,
        circuitName: r.circuitName,
        country: r.country,
        date: r.date,
        hasSprint: r.hasSprint,
      );

  RacesCompanion _raceToCompanion(Race r) => RacesCompanion.insert(
        season: r.season,
        round: r.round,
        raceName: r.raceName,
        circuitId: r.circuitId,
        circuitName: r.circuitName,
        country: r.country,
        date: r.date,
        hasSprint: Value(r.hasSprint),
      );

  ResultsCompanion _resultToCompanion(RaceResult r) => ResultsCompanion.insert(
        season: r.season,
        round: r.round,
        driverId: r.driverId,
        constructorId: r.constructorId,
        gridPosition: r.gridPosition,
        finishPosition: Value(r.finishPosition),
        status: r.status,
        fastestLap: Value(r.fastestLap),
      );

  QualifyingResultsCompanion _qualiToCompanion(QualifyingResult q) =>
      QualifyingResultsCompanion.insert(
        season: q.season,
        round: q.round,
        driverId: q.driverId,
        position: q.position,
        q1Millis: Value(q.q1?.inMilliseconds),
        q2Millis: Value(q.q2?.inMilliseconds),
        q3Millis: Value(q.q3?.inMilliseconds),
      );
}
