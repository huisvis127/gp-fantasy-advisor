/// Resultado del motor de predicción para un piloto o constructor de cara
/// al próximo GP (sección 5.1 del plan). `breakdown` alimenta la barra de
/// "por qué" en la pantalla de Predicciones.
class AssetPrediction {
  const AssetPrediction({
    required this.assetId,
    required this.expectedPoints,
    required this.winProbability,
    required this.podiumProbability,
    required this.top10Probability,
    required this.priceMillions,
    required this.breakdown,
  });

  final String assetId;
  final double expectedPoints;
  final double winProbability;
  final double podiumProbability;
  final double top10Probability;
  final double priceMillions;

  /// Nombre de feature -> valor normalizado 0-100, para el desglose "por qué".
  final Map<String, double> breakdown;

  /// Puntos-por-valor, equivalente a `scorePerValue` de la app de referencia.
  double get pointsPerValue => priceMillions <= 0 ? 0 : expectedPoints / priceMillions;
}
