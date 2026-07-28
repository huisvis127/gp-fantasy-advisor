import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';

/// Traduce distribuciones de posición probable en puntos fantasy esperados,
/// usando la tabla `scoring_2026.json` (sección 2 del plan: "la tabla de
/// puntuación y las reglas viven en un JSON versionado, no hardcodeadas").
class ScoringTable {
  ScoringTable._(this._data);

  final Map<String, dynamic> _data;

  static Future<ScoringTable> load() async {
    final raw = await rootBundle.loadString(AssetPaths.scoringTable);
    return ScoringTable._(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Constructor para tests / backtesting sin cargar assets de Flutter.
  factory ScoringTable.fromJson(Map<String, dynamic> json) =>
      ScoringTable._(json);

  Map<String, int> get racePositionPoints =>
      (_data['race']['position_points'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));

  Map<String, int> get qualifyingPositionPoints =>
      (_data['qualifying']['position_points'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));

  Map<String, int> get sprintPositionPoints =>
      ((_data['sprint']?['position_points'] as Map<String, dynamic>?) ??
              const <String, dynamic>{})
          .map((k, v) => MapEntry(k, v as int));

  int get fastestLapPoints => _data['race']['fastest_lap'] as int;
  int get dnfPenalty => _data['race']['dnf'] as int;
  int get sprintDnfPenalty => (_data['sprint']?['dnf'] as num?)?.toInt() ?? -10;
  int get bothCarsQ3Bonus => _data['constructor']['both_cars_q3_bonus'] as int;

  int pointsForRacePosition(int? position) {
    if (position == null) return dnfPenalty;
    return racePositionPoints[position.toString()] ?? 0;
  }

  int pointsForQualifyingPosition(int position) {
    return qualifyingPositionPoints[position.toString()] ?? 0;
  }

  int pointsForSprintPosition(int position) {
    return sprintPositionPoints[position.toString()] ?? 0;
  }

  /// Puntos de clasificación esperados antes de que comience Qualifying.
  double expectedQualifyingPoints({
    required List<double> positionProbabilities,
  }) {
    return _expectedPositionPoints(
      positionProbabilities,
      pointsForQualifyingPosition,
    );
  }

  /// Puntos de carrera esperados: posición final y riesgo de DNF.
  ///
  /// Los extras (adelantamientos, posiciones ganadas, vuelta rápida y DOTD)
  /// quedan fuera deliberadamente: el backtest 2025 mostró que añadir su
  /// media reciente empeoraba la correlación fuera de muestra.
  double expectedRacePoints({
    required List<double> positionProbabilities,
    required double dnfProbability,
  }) {
    final finishPoints = _expectedPositionPoints(
      positionProbabilities,
      (position) => pointsForRacePosition(position),
    );
    return finishPoints * (1 - dnfProbability) + dnfProbability * dnfPenalty;
  }

  /// Puntos de Sprint esperados en fines de semana Sprint.
  double expectedSprintPoints({
    required List<double> positionProbabilities,
    required double dnfProbability,
  }) {
    final finishPoints = _expectedPositionPoints(
      positionProbabilities,
      pointsForSprintPosition,
    );
    return finishPoints * (1 - dnfProbability) +
        dnfProbability * sprintDnfPenalty;
  }

  double _expectedPositionPoints(
    List<double> positionProbabilities,
    int Function(int position) pointsForPosition,
  ) {
    var expected = 0.0;
    for (var i = 0; i < positionProbabilities.length; i++) {
      expected +=
          positionProbabilities[i] * pointsForPosition(i + 1).toDouble();
    }
    return expected;
  }
}

/// Convierte puntuaciones brutas (0-100) de N pilotos en una distribución de
/// probabilidad por posición mediante softmax, tal y como describe la
/// sección 5.1: "probabilidad de victoria/podio/top-10 mediante un softmax
/// sobre las puntuaciones de los pilotos".
class SoftmaxDistribution {
  /// `scores` en el mismo orden que los pilotos a comparar. `temperature`
  /// controla cuánto se concentra la probabilidad en los mejores (más bajo
  /// = más determinista); se calibra en el backtesting junto a w1..w8.
  static List<double> winProbabilities(List<double> scores,
      {double temperature = 12.0}) {
    final exps = scores.map((s) => exp(s / temperature)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  /// Aproxima la probabilidad de acabar en cada posición final ordenando
  /// simulaciones Monte Carlo ligeras sobre ruido gaussiano por piloto.
  /// Suficientemente bueno para v1 (modelo transparente, sección 5.1);
  /// v2 puede sustituir esto por un modelo de posiciones completo.
  static List<List<double>> positionProbabilityMatrix(
    List<double> scores, {
    int simulations = 2000,
    double noiseStdDev = 8.0,
    int? seed,
  }) {
    final random = Random(seed);
    final n = scores.length;
    final counts = List.generate(n, (_) => List.filled(n, 0));

    for (var s = 0; s < simulations; s++) {
      final noisy = List.generate(n, (i) {
        final gaussian = _gaussianNoise(random) * noiseStdDev;
        return MapEntry(i, scores[i] + gaussian);
      });
      noisy.sort((a, b) => b.value.compareTo(a.value));
      for (var pos = 0; pos < n; pos++) {
        counts[noisy[pos].key][pos] += 1;
      }
    }

    return counts
        .map((row) => row.map((c) => c / simulations).toList())
        .toList();
  }

  static double _gaussianNoise(Random random) {
    // Box-Muller
    final u1 = 1 - random.nextDouble();
    final u2 = random.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}
