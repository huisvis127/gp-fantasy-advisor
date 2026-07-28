import '../models/prediction.dart';
import 'driver_context.dart';
import 'model_weights.dart';
import 'scoring.dart';

/// Motor de predicción v1: modelo de puntuación ponderada, transparente y
/// calibrable (sección 5.1 del plan). Corre en un Isolate desde la UI
/// (ver domain/engine/isolate_runner.dart) para no congelar el hilo principal.
///
/// La suma ponderada de facetas produce una señal de rendimiento. Esa señal
/// se transforma en distribuciones de posición y, finalmente, en:
///
/// `E[puntos] = E[clasificación] + E[carrera] + E[Sprint, si existe]`
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
          _weights.w2RitmoUnaVueltaHistorico * features['ritmo_una_vuelta']! +
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
    final racePositionMatrix =
        SoftmaxDistribution.positionProbabilityMatrix(scoreList);
    final qualifyingScores = drivers
        .map((ctx) => _qualifyingScore(breakdowns[ctx.driverId]!))
        .toList();
    final qualifyingPositionMatrix =
        SoftmaxDistribution.positionProbabilityMatrix(qualifyingScores);

    final predictions = <AssetPrediction>[];
    for (var i = 0; i < drivers.length; i++) {
      final ctx = drivers[i];
      final positionProbs = racePositionMatrix[i];
      final podiumProb = positionProbs.length >= 3
          ? positionProbs[0] + positionProbs[1] + positionProbs[2]
          : 0.0;
      final top10Prob =
          positionProbs.take(10).fold<double>(0, (sum, p) => sum + p);
      final dnfProb =
          (breakdowns[ctx.driverId]!['riesgo_dnf']! / 100).clamp(0.0, 1.0);
      final qualifyingPoints = _scoring.expectedQualifyingPoints(
        positionProbabilities: qualifyingPositionMatrix[i],
      );
      final racePoints = _scoring.expectedRacePoints(
        positionProbabilities: positionProbs,
        dnfProbability: dnfProb,
      );
      // La Sprint tiene aproximadamente un tercio de la distancia de un GP.
      // Reducimos el riesgo de abandono, conservando el riesgo de incidentes
      // de salida y de fiabilidad.
      final sprintPoints = isSprintWeekend
          ? _scoring.expectedSprintPoints(
              positionProbabilities: positionProbs,
              dnfProbability: (dnfProb * .5).clamp(0.0, 1.0),
            )
          : 0.0;
      final expectedPoints = qualifyingPoints + racePoints + sprintPoints;

      predictions.add(AssetPrediction(
        assetId: ctx.driverId,
        expectedPoints: expectedPoints,
        winProbability: winProbs[i],
        podiumProbability: podiumProb,
        top10Probability: top10Prob,
        priceMillions: currentPricesMillions[ctx.driverId] ?? 0,
        breakdown: breakdowns[ctx.driverId]!,
        pointBreakdown: {
          'clasificacion': qualifyingPoints,
          'carrera': racePoints,
          if (isSprintWeekend) 'sprint': sprintPoints,
        },
      ));
    }
    return predictions;
  }

  /// Señal específica para prever Qualifying, construida únicamente con
  /// información conocida antes de la sesión. Se renormalizan las facetas de
  /// una vuelta, forma y coche; nunca se usa la clasificación del GP actual.
  double _qualifyingScore(Map<String, double> features) {
    final components = <(double, double)>[
      (_weights.w2RitmoUnaVueltaHistorico, features['ritmo_una_vuelta']!),
      (_weights.w3VueltaRapida, features['vuelta_rapida']!),
      (_weights.w5Forma, features['forma']!),
      (_weights.w7FormaEquipo, features['forma_equipo']!),
    ];
    final totalWeight =
        components.fold<double>(0, (sum, entry) => sum + entry.$1);
    if (totalWeight <= 0) return features['ritmo_una_vuelta']!;
    return components.fold<double>(
          0,
          (sum, entry) => sum + entry.$1 * entry.$2,
        ) /
        totalWeight;
  }

  Map<String, double> _extractFeatures(
    DriverContext ctx, {
    required bool isSprintWeekend,
  }) {
    final features = {
      'ritmo_carrera': _weightedRecentPositionScore(
          ctx.recentRaceFinishPositions, ctx.gridSize),
      'ritmo_una_vuelta':
          _averagePositionScore(ctx.recentOneLapPositions, ctx.gridSize),
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
    // única y el ritmo de tandas se mezclan progresivamente con el histórico.
    // Solo pueden llegar FP1/FP2/FP3: quali y SQ se excluyen en dos capas
    // (WeekendData y la tabla de pesos del modelo).
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
        final practiceOneLap =
            (100 - (oneLapGap / 3.0) * 100).clamp(0.0, 100.0);
        final blend = _weights.practiceBlendFor(
          kind: 'one_lap',
          availableSessions: sessionWeights.keys.toSet(),
        );
        features['vuelta_rapida'] =
            features['vuelta_rapida']! * (1 - blend) + practiceOneLap * blend;
      }
      if (paceGap != null) {
        final weekendPace = (100 - (paceGap / 2.0) * 100).clamp(0.0, 100.0);
        final blend = _weights.practiceBlendFor(
          kind: 'pace',
          availableSessions: sessionWeights.keys.toSet(),
        );
        features['ritmo_carrera'] =
            features['ritmo_carrera']! * (1 - blend) + weekendPace * blend;
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
