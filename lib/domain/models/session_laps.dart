/// Agregado por sesión (no vuelta a vuelta) construido a partir de OpenF1,
/// tal y como describe la sección 5.1 del plan: mejor stint, media top-2 y
/// media top-K de stints largos, usadas para medir ritmo real filtrando
/// vueltas sucias (tráfico, safety car, box).
class SessionLapsAggregate {
  const SessionLapsAggregate({
    required this.season,
    required this.round,
    required this.sessionKey, // "fp1" | "fp2" | "fp3" | "quali" | "sq"
    required this.driverId,
    required this.bestStintAvgMs,
    required this.top2StintsAvgMs,
    required this.bestLapMs,
    required this.lapCount,
  });

  final int season;
  final int round;
  final String sessionKey;
  final String driverId;
  final double bestStintAvgMs;
  final double top2StintsAvgMs;
  final double bestLapMs;
  final int lapCount;
}
