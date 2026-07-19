import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// Base de datos SQLite local (paquete drift). Única fuente de verdad para
/// la UI a través de `DataRepository` (sección 3 del plan). Todas las clases
/// de fila generadas terminan en `Row` (ver tables.dart) para no chocar con
/// los modelos de dominio homónimos.
@DriftDatabase(
  tables: [
    Drivers,
    Constructors,
    Races,
    Results,
    QualifyingResults,
    SessionLaps,
    FantasyPrices,
    FantasyPointsTable,
    MyTeamTable,
    PredictionsCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Sin migraciones todavía (schemaVersion 1). Añadir aquí cuando
      // cambie el esquema en versiones futuras publicadas en Play.
    },
  );

  // ---- Helpers de lectura usados por DataRepository ----

  Future<List<DriverRow>> allDrivers() => select(drivers).get();

  Future<List<ConstructorRow>> allConstructors() => select(constructors).get();

  Future<List<RaceRow>> allRaces(int season) =>
      (select(races)..where((r) => r.season.equals(season))).get();

  Future<RaceRow?> nextRace(int season, DateTime after) async {
    final rows =
        await (select(races)
              ..where(
                (r) =>
                    r.season.equals(season) &
                    r.date.isBiggerOrEqualValue(after),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.date)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Filtro "estrictamente anterior al GP (beforeSeason, beforeRound)":
  /// permite predecir cualquier GP usando solo datos previos a él
  /// (sin mirar el futuro, como exige la sección 5.2 del plan).
  Expression<bool> _beforeCutoff(
    GeneratedColumn<int> season,
    GeneratedColumn<int> round,
    int beforeSeason,
    int beforeRound,
  ) {
    return season.isSmallerThanValue(beforeSeason) |
        (season.equals(beforeSeason) & round.isSmallerThanValue(beforeRound));
  }

  Future<List<ResultRow>> resultsForDriver(
    String driverId, {
    int limit = 8,
    int? beforeSeason,
    int? beforeRound,
  }) {
    final query = select(results)..where((r) => r.driverId.equals(driverId));
    if (beforeSeason != null && beforeRound != null) {
      query.where(
        (r) => _beforeCutoff(r.season, r.round, beforeSeason, beforeRound),
      );
    }
    query
      ..orderBy([
        (r) => OrderingTerm.desc(r.season),
        (r) => OrderingTerm.desc(r.round),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<List<QualifyingResultRow>> qualifyingForDriver(
    String driverId, {
    int limit = 8,
    int? beforeSeason,
    int? beforeRound,
  }) {
    final query = select(qualifyingResults)
      ..where((r) => r.driverId.equals(driverId));
    if (beforeSeason != null && beforeRound != null) {
      query.where(
        (r) => _beforeCutoff(r.season, r.round, beforeSeason, beforeRound),
      );
    }
    query
      ..orderBy([
        (r) => OrderingTerm.desc(r.season),
        (r) => OrderingTerm.desc(r.round),
      ])
      ..limit(limit);
    return query.get();
  }

  /// Pilotos con algún resultado en la temporada dada (la parrilla real de
  /// esa temporada, para no predecir a pilotos retirados de años anteriores).
  Future<Set<String>> driverIdsWithResultsInSeason(int season) async {
    final query = selectOnly(results, distinct: true)
      ..addColumns([results.driverId])
      ..where(results.season.equals(season));
    final rows = await query.get();
    return rows.map((row) => row.read(results.driverId)!).toSet();
  }

  /// Rondas de una temporada que ya tienen resultados cacheados (para la
  /// sincronización incremental: no re-descargar lo que ya está).
  Future<Set<int>> roundsWithResults(int season) async {
    final query = selectOnly(results, distinct: true)
      ..addColumns([results.round])
      ..where(results.season.equals(season));
    final rows = await query.get();
    return rows.map((row) => row.read(results.round)!).toSet();
  }

  Future<List<ResultRow>> resultsForRace(int season, int round) => (select(
    results,
  )..where((r) => r.season.equals(season) & r.round.equals(round))).get();

  Future<List<QualifyingResultRow>> qualifyingForRace(int season, int round) =>
      (select(
        qualifyingResults,
      )..where((r) => r.season.equals(season) & r.round.equals(round))).get();

  Future<bool> hasAnyPrices() async {
    final rows = await (select(fantasyPrices)..limit(1)).get();
    return rows.isNotEmpty;
  }

  Future<double?> latestPrice(String assetId, String assetType) async {
    final rows =
        await (select(fantasyPrices)
              ..where(
                (r) =>
                    r.assetId.equals(assetId) & r.assetType.equals(assetType),
              )
              ..orderBy([
                (r) => OrderingTerm.desc(r.season),
                (r) => OrderingTerm.desc(r.round),
              ])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first.priceMillions;
  }

  Future<List<ResultRow>> resultsForDriverAtCircuit(
    String driverId,
    String circuitId, {
    int limit = 4,
    int? beforeSeason,
    int? beforeRound,
  }) async {
    final query =
        select(results).join([
            innerJoin(
              races,
              races.season.equalsExp(results.season) &
                  races.round.equalsExp(results.round),
            ),
          ])
          ..where(
            results.driverId.equals(driverId) &
                races.circuitId.equals(circuitId),
          )
          ..orderBy([OrderingTerm.desc(races.season)])
          ..limit(limit);
    if (beforeSeason != null && beforeRound != null) {
      query.where(
        _beforeCutoff(results.season, results.round, beforeSeason, beforeRound),
      );
    }
    final rows = await query.get();
    return rows.map((r) => r.readTable(results)).toList();
  }

  Future<List<ResultRow>> resultsForConstructor(
    String constructorId, {
    int limit = 6,
    int? beforeSeason,
    int? beforeRound,
  }) {
    final query = select(results)
      ..where((r) => r.constructorId.equals(constructorId));
    if (beforeSeason != null && beforeRound != null) {
      query.where(
        (r) => _beforeCutoff(r.season, r.round, beforeSeason, beforeRound),
      );
    }
    query
      ..orderBy([
        (r) => OrderingTerm.desc(r.season),
        (r) => OrderingTerm.desc(r.round),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> upsertDrivers(List<Insertable<DriverRow>> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(drivers, rows));
  }

  Future<void> updateDriverConstructors(
    Map<String, String> constructorByDriver,
  ) async {
    await batch((b) {
      for (final entry in constructorByDriver.entries) {
        b.update(
          drivers,
          DriversCompanion(constructorId: Value(entry.value)),
          where: (d) => d.id.equals(entry.key),
        );
      }
    });
  }

  Future<void> upsertConstructors(List<Insertable<ConstructorRow>> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(constructors, rows));
  }

  Future<void> upsertRaces(List<Insertable<RaceRow>> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(races, rows));
  }

  Future<void> upsertResults(List<Insertable<ResultRow>> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(results, rows));
  }

  Future<void> upsertQualifying(
    List<Insertable<QualifyingResultRow>> rows,
  ) async {
    await batch((b) => b.insertAllOnConflictUpdate(qualifyingResults, rows));
  }

  Future<void> upsertPrices(List<Insertable<FantasyPriceRow>> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(fantasyPrices, rows));
  }

  Future<void> saveMyTeam(MyTeamTableCompanion row) async {
    await into(myTeamTable).insertOnConflictUpdate(row);
  }

  Future<MyTeamRow?> loadMyTeam() async {
    final rows = await (select(
      myTeamTable,
    )..where((r) => r.id.equals(0))).get();
    return rows.isEmpty ? null : rows.first;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gp_fantasy_advisor.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
