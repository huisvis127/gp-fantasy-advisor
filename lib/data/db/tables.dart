import 'package:drift/drift.dart';

/// Tablas drift (SQLite) — caché local, sección 3 y 4 del plan.
/// La app debe funcionar 100% en modo lectura sin conexión con estos datos.

// Nota: todas las tablas usan @DataClassName('...Row') para que las clases
// de fila generadas por drift (p.ej. `RaceRow`) nunca choquen por nombre con
// los modelos de dominio equivalentes (p.ej. `Race` en domain/models/race.dart).

@DataClassName('DriverRow')
class Drivers extends Table {
  TextColumn get id => text()(); // driverId (jolpica)
  TextColumn get code => text().withLength(min: 2, max: 3)();
  TextColumn get givenName => text()();
  TextColumn get familyName => text()();
  TextColumn get constructorId => text()();
  IntColumn get number => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ConstructorRow')
class Constructors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get nationality => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RaceRow')
class Races extends Table {
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  TextColumn get raceName => text()();
  TextColumn get circuitId => text()();
  TextColumn get circuitName => text()();
  TextColumn get country => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get hasSprint => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {season, round};
}

@DataClassName('ResultRow')
class Results extends Table {
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  TextColumn get driverId => text()();
  TextColumn get constructorId => text()();
  IntColumn get gridPosition => integer()();
  IntColumn get finishPosition => integer().nullable()();
  TextColumn get status => text()();
  BoolColumn get fastestLap => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {season, round, driverId};
}

@DataClassName('QualifyingResultRow')
class QualifyingResults extends Table {
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  TextColumn get driverId => text()();
  IntColumn get position => integer()();
  IntColumn get q1Millis => integer().nullable()();
  IntColumn get q2Millis => integer().nullable()();
  IntColumn get q3Millis => integer().nullable()();

  @override
  Set<Column> get primaryKey => {season, round, driverId};
}

/// Agregados por sesión (no vuelta a vuelta), calculados a partir de OpenF1.
@DataClassName('SessionLapRow')
class SessionLaps extends Table {
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  TextColumn get sessionKey => text()(); // fp1 | fp2 | fp3 | quali | sq
  TextColumn get driverId => text()();
  RealColumn get bestStintAvgMs => real()();
  RealColumn get top2StintsAvgMs => real()();
  RealColumn get bestLapMs => real()();
  IntColumn get lapCount => integer()();

  @override
  Set<Column> get primaryKey => {season, round, sessionKey, driverId};
}

@DataClassName('FantasyPriceRow')
class FantasyPrices extends Table {
  TextColumn get assetId => text()();
  TextColumn get assetType => text()(); // "driver" | "constructor"
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  RealColumn get priceMillions => real()();

  @override
  Set<Column> get primaryKey => {assetId, assetType, season, round};
}

@DataClassName('FantasyPointsRow')
class FantasyPointsTable extends Table {
  TextColumn get assetId => text()();
  TextColumn get assetType => text()();
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  IntColumn get points => integer()();

  @override
  Set<Column> get primaryKey => {assetId, assetType, season, round};
}

/// Equipo del usuario (importado o manual). Fila única (id fijo = 0).
@DataClassName('MyTeamRow')
class MyTeamTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get driverIdsCsv => text()();
  TextColumn get constructorIdsCsv => text()();
  RealColumn get remainingBudgetMillions => real()();
  TextColumn get boostedDriverId => text().nullable()();
  TextColumn get source => text()();
  TextColumn get chipsUsedCsv => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Caché de la última predicción calculada, para poder mostrar algo
/// instantáneamente mientras se refresca en segundo plano.
@DataClassName('PredictionCacheRow')
class PredictionsCache extends Table {
  TextColumn get assetId => text()();
  TextColumn get assetType => text()();
  IntColumn get season => integer()();
  IntColumn get round => integer()();
  RealColumn get expectedPoints => real()();
  RealColumn get winProbability => real()();
  RealColumn get podiumProbability => real()();
  RealColumn get top10Probability => real()();
  RealColumn get priceMillions => real()();
  TextColumn get breakdownJson => text()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetId, assetType, season, round};
}
