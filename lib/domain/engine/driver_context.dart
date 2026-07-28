/// Datos crudos de un piloto necesarios para extraer las 8 features de la
/// sección 5.1 del plan, ya recortados a las ventanas que pide cada feature
/// (últimas 5/8 carreras, últimos 4 años en el circuito, etc.) por quien
/// construye este objeto (normalmente un provider que lee `DataRepository`).
class DriverContext {
  const DriverContext({
    required this.driverId,
    required this.constructorId,
    required this.recentRaceFinishPositions, // más reciente primero, null = DNF
    required this.recentOneLapPositions, // GPs anteriores, más reciente primero
    required this.recentFastestLapGapPercent, // 0 = vuelta rápida de la sesión
    required this.circuitHistoryFinishPositions,
    required this.constructorRecentPoints,
    required this.driverDnfRateLast2Seasons,
    required this.constructorDnfRateLast2Seasons,
    required this.gridSize,
    this.sessionAggregates = const {},
  });

  final String driverId;
  final String constructorId;

  /// Hasta 8 elementos (más reciente primero): el motor usa los 5 más
  /// recientes para el ritmo de carrera (peso decreciente 5-4-3-2-1) y los 8
  /// completos para la consistencia y la tendencia de forma (sección 5.1).
  final List<int?> recentRaceFinishPositions;

  /// Posición a una vuelta de GPs anteriores. Es información conocida antes
  /// del cierre; nunca contiene la clasificación del GP que se predice.
  final List<int> recentOneLapPositions;

  /// Diferencia porcentual con la vuelta rápida de la sesión, por sesión
  /// reciente. 0.0 = fue la vuelta rápida.
  final List<double> recentFastestLapGapPercent;

  /// Resultados en el circuito de este GP en los últimos 4 años.
  final List<int?> circuitHistoryFinishPositions;

  /// Puntos del constructor (reales, no fantasy) en las últimas 3 carreras.
  final List<double> constructorRecentPoints;

  final double driverDnfRateLast2Seasons;
  final double constructorDnfRateLast2Seasons;

  /// Nº de pilotos en parrilla esta temporada (para normalizar posiciones).
  final int gridSize;

  /// Agregados de sesión del fin de semana en curso (OpenF1), clave =
  /// Solo "fp1"|"fp2"|"fp3". Qualifying y Sprint Qualifying están excluidas.
  final Map<String, double> sessionAggregates;
}
