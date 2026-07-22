import '../models/prediction.dart';
import 'driver_context.dart';
import 'model_weights.dart';
import 'scoring.dart';

/// Motor de predicción v1: modelo de puntuación ponderada, transparente y
/// calibrable (sección 5.1 del plan). Corre en un Isolate desde la UI
/// (ver domain/engine/isolate_runner.dart) para no congelar el hilo principal.
///
/// `E[puntos] = w1·RitmoCarrera + w2·RitmoClasificacion + w3·VueltaRapida
///            + w4·Consistencia + w5·Forma + w6·AfinidadCircuito
///            + w7·FormaEquipo - w8·RiesgoDNF`
///
/// Cada feature se normaliza a 0-100 antes de aplicar los pesos, y el
/// desglose por feature se expone en `AssetPrediction.breakdown` para la
/// barra de "por qué" de la pantalla de Predicciones (sección 6).
class PredictionEngine {
  const PredictionEngine(this._weights, this._scoring);

  final ModelWeights _weights;
  final ScoringTable _scoring;

  /// Predice a todos los pilotos de una vez porque las probabilidades
  /// (softmax) son relativas al resto de la parrilla (sección 5.1).
  List<AssetPrediction> predictDrivers({
    required List<DriverContext> drivers,
    required Map<String, double> currentPricesMillions,
    required bool isSprintWeekend,
  }) {
    final rawScores = <String, double>{};
    final breakdowns = <String, Map<String, double>>{};

    for (final ctx in drivers) {
      final features = _extractFeatures(ctx, isSprintWeekend: isSprintWeekend);
      final score = _weights.w1RitmoCarrera * features['ritmo_carrera']! +
          _weights.w2RitmoClasificacion * features['ritmo_clasificacion']! +
          _weights.w3VueltaRapida * features['vuelta_rapida']! +
          _weights.w4Consistencia * features['consistencia']! +
          _weights.w5Forma * features['forma']! +
          _weights.w6AfinidadCircuito * features['afinidad_circuito']! +
          _weights.w7FormaEquipo * features['forma_equipo']! -
          _weights.w8RiesgoDnf * features['riesgo_dnf']!;
      rawScores[ctx.driverId] = score;
      breakdowns[ctx.driverId] = features;
    }

    final ids = drivers.map((d) => d.driverId).toList();
    final scoreList = ids.map((id) => rawScores[id]!).toList();
    final winProbs = SoftmaxDistribution.winProbabilities(scoreList);
    final positionMatrix =
        SoftmaxDistribution.positionProbabilityMatrix(scoreList);

    final predictions = <AssetPrediction>[];
    for (var i = 0; i < drivers.length; i++) {
      final ctx = drivers[i];
      final positionProbs = positionMatrix[i];
      final podiumProb = positionProbs.length >= 3
          ? positionProbs[0] + positionProbs[1] + positionProbs[2]
          : 0.0;
      final top10Prob =
          positionProbs.take(10).fold<double>(0, (sum, p) => sum + p);
      final dnfProb = ctx.driverDnfRateLast2Seasons;
      final expectedPoints = _scoring.expectedRacePoints(
        positionProbabilities: positionProbs,
        fastestLapProbability:
            breakdowns[ctx.driverId]!['vuelta_rapida']! / 100 * 0.15,
        dnfProbability: dnfProb,
      );

      predictions.add(AssetPrediction(
        assetId: ctx.driverId,
        expectedPoints: expectedPoints,
        winProbability: winProbs[i],
        podiumProbability: podiumProb,
        top10Probability: top10Prob,
        priceMillions: currentPricesMillions[ctx.driverId] ?? 0,
        breakdown: breakdowns[ctx.driverId]!,
      ));
    }
    return predictions;
  }

  Map<String, double> _extractFeatures(
    DriverContext ctx, {
    required bool isSprintWeekend,
  }) {
    final features = {
      'ritmo_carrera': _weightedRecentPositionScore(
          ctx.recentRaceFinishPositions, ctx.gridSize),
      'ritmo_clasificacion':
          _averagePositionScore(ctx.recentQualifyingPositions, ctx.gridSize),
      'vuelta_rapida': _fastestLapScore(ctx.recentFastestLapGapPercent),
      'consistencia':
          _consistencyScore(ctx.recentRaceFinishPositions, ctx.gridSize),
      'forma': _formTrendScore(ctx.recentRaceFinishPositions, ctx.gridSize),
      'afinidad_circuito': _circuitAffinityScore(
          ctx.circuitHistoryFinishPositions, ctx.gridSize),
      'circuit_history_count':
          ctx.circuitHistoryFinishPositions.length.toDouble(),
      'forma_equipo': _constructorFormScore(ctx.constructorRecentPoints),
      'riesgo_dnf': (ctx.driverDnfRateLast2Seasons * 0.6 +
              ctx.constructorDnfRateLast2Seasons * 0.4) *
          100,
    };

    // Predicción por etapas (docs/PLAN_PREDICCION_SESIONES.md): si hay
    // agregados del fin de semana en curso (claves 'onelap:fp1',
    // 'pace:fp2'... con gap % contra el mejor de cada sesión), la vuelta
    // única del finde SUSTITUYE a la aproximación histórica y el ritmo de
    // tandas se MEZCLA 50/50 con el histórico. Los pesos por sesión salen
    // de la tabla calibrada, repartiendo el peso de las sesiones ausentes.
    if (ctx.sessionAggregates.isNotEmpty) {
      final available = <String>{};
      for (final key in ctx.sessionAggregates.keys) {
        final parts = key.split(':');
        if (parts.length == 2) available.add(parts[1]);
      }
      final sessionWeights = _weights.sessionWeightsFor(
        isSprint: isSprintWeekend,
        availableSessions: available,
      );
      final oneLapGap =
          _sessionWeightedGap('onelap', sessionWeights, ctx.sessionAggregates);
      final paceGap =
          _sessionWeightedGap('pace', sessionWeights, ctx.sessionAggregates);
      if (oneLapGap != null) {
        // 0% de gap = 100; 3% o más = 0 (misma escala que el histórico).
        features['vuelta_rapida'] =
            (100 - (oneLapGap / 3.0) * 100).clamp(0.0, 100.0);
      }
      if (paceGap != null) {
        final weekendPace = (100 - (paceGap / 2.0) * 100).clamp(0.0, 100.0);
        features['ritmo_carrera'] =
            features['ritmo_carrera']! * 0.5 + weekendPace * 0.5;
      }
    }

    return features;
  }

  /// Gap % medio ponderado por sesión para la serie `kind` ('onelap'/'pace').
  /// Devuelve null si el piloto no tiene datos en ninguna sesión disponible.
  double? _sessionWeightedGap(
    String kind,
    Map<String, double> sessionWeights,
    Map<String, double> aggregates,
  ) {
    double sum = 0;
    double weightTotal = 0;
    sessionWeights.forEach((session, weight) {
      final gap = aggregates['$kind:$session'];
      if (gap != null) {
        sum += gap * weight;
        weightTotal += weight;
      }
    });
    return weightTotal == 0 ? null : sum / weightTotal;
  }

  // ---- Features (todas normalizadas 0-100, 100 = mejor) ----

  double _positionToScore(int position, int gridSize) {
    if (gridSize <= 1) return 100;
    return (100 * (gridSize - position) / (gridSize - 1)).clamp(0, 100);
  }

  double _weightedRecentPositionScore(List<int?> positions, int gridSize) {
    final recent = positions.take(5).toList();
    if (recent.isEmpty) return 50;
    const weights = [5, 4, 3, 2, 1];
    double weightedSum = 0;
    double weightTotal = 0;
    for (var i = 0; i < recent.length; i++) {
      final pos = recent[i];
      // DNF penaliza como si hubiera acabado último, no se ignora.
      final score = _positionToScore(pos ?? gridSize, gridSize);
      weightedSum += score * weights[i];
      weightTotal += weights[i];
    }
    return weightTotal == 0 ? 50 : weightedSum / weightTotal;
  }

  double _averagePositionScore(List<int> positions, int gridSize) {
    if (positions.isEmpty) return 50;
    final scores = positions.map((p) => _positionToScore(p, gridSize));
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  double _fastestLapScore(List<double> gapPercentages) {
    if (gapPercentages.isEmpty) return 30;
    final avgGap =
        gapPercentages.reduce((a, b) => a + b) / gapPercentages.length;
    // 0% de gap = 100 puntos; 3% o más de gap = 0 puntos.
    return (100 - (avgGap / 3.0) * 100).clamp(0, 100);
  }

  double _consistencyScore(List<int?> positions, int gridSize) {
    final recent = positions.take(8).toList();
    if (recent.length < 2) return 50;
    final scores =
        recent.map((p) => _positionToScore(p ?? gridSize, gridSize)).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
            scores.length;
    final stdDev = variance <= 0 ? 0.0 : _sqrt(variance);
    // Menor desviación típica = más consistente = puntuación más alta.
    return (100 - stdDev).clamp(0, 100);
  }

  double _formTrendScore(List<int?> positions, int gridSize) {
    if (positions.length < 4) return 50;
    final last3 =
        positions.take(3).map((p) => _positionToScore(p ?? gridSize, gridSize));
    final prev3 = positions
        .skip(3)
        .take(3)
        .map((p) => _positionToScore(p ?? gridSize, gridSize));
    if (prev3.isEmpty) return 50;
    final avgLast3 = last3.reduce((a, b) => a + b) / last3.length;
    final avgPrev3 = prev3.reduce((a, b) => a + b) / prev3.length;
    // Diferencia centrada en 50: mejora = por encima de 50.
    return (50 + (avgLast3 - avgPrev3)).clamp(0, 100);
  }

  double _circuitAffinityScore(List<int?> circuitHistory, int gridSize) {
    if (circuitHistory.isEmpty) {
      return 50; // neutro si no hay datos (sección 5.1)
    }
    const weights = [5.0, 4.0, 3.0, 2.0, 1.0];
    var total = 0.0;
    var weightTotal = 0.0;
    for (var i = 0; i < circuitHistory.length && i < weights.length; i++) {
      total += _positionToScore(circuitHistory[i] ?? gridSize, gridSize) *
          weights[i];
      weightTotal += weights[i];
    }
    return weightTotal == 0 ? 50 : total / weightTotal;
  }

  double _constructorFormScore(List<double> recentPoints) {
    if (recentPoints.isEmpty) return 50;
    final avg = recentPoints.reduce((a, b) => a + b) / recentPoints.length;
    // Normalización simple: 0 puntos por carrera = 0, ~43 (máximo doble
    // podio + vuelta rápida) = 100. Ajustar tras el backtesting real.
    return (avg / 43.0 * 100).clamp(0, 100);
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double x = value;
    double prev;
    do {
      prev = x;
      x = (x + value / x) / 2;
    } while ((prev - x).abs() > 1e-9);
    return x;
  }
}
