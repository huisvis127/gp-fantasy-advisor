import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/scoring.dart';

Map<String, dynamic> _sampleScoringJson() {
  return {
    'race': {
      'position_points': {
        '1': 25, '2': 18, '3': 15, '4': 12, '5': 10,
        '6': 8, '7': 6, '8': 4, '9': 2, '10': 1,
      },
      'fastest_lap': 5,
      'dnf': -20,
    },
    'qualifying': {
      'position_points': {'1': 10, '2': 9, '3': 8},
    },
    'constructor': {'both_cars_q3_bonus': 10},
  };
}

void main() {
  group('ScoringTable', () {
    test('pointsForRacePosition devuelve los puntos correctos', () {
      final table = ScoringTable.fromJson(_sampleScoringJson());
      expect(table.pointsForRacePosition(1), 25);
      expect(table.pointsForRacePosition(10), 1);
      expect(table.pointsForRacePosition(15), 0); // fuera de la tabla
      expect(table.pointsForRacePosition(null), -20); // DNF
    });

    test('expectedRacePoints con certeza de P1 da los puntos de P1', () {
      final table = ScoringTable.fromJson(_sampleScoringJson());
      final probs = [1.0, 0.0, 0.0];
      final expected = table.expectedRacePoints(
        positionProbabilities: probs,
        fastestLapProbability: 0,
        dnfProbability: 0,
      );
      expect(expected, 25.0);
    });

    test('expectedRacePoints reparte el DNF correctamente', () {
      final table = ScoringTable.fromJson(_sampleScoringJson());
      final probs = [1.0, 0.0, 0.0];
      final expected = table.expectedRacePoints(
        positionProbabilities: probs,
        fastestLapProbability: 0,
        dnfProbability: 0.5,
      );
      // 50% de posibilidades de acabar P1 (25 pts) + 50% de DNF (-20 pts).
      expect(expected, closeTo(0.5 * 25 + 0.5 * -20, 0.001));
    });
  });

  group('SoftmaxDistribution', () {
    test('winProbabilities suma 1 y favorece la puntuación más alta', () {
      final probs = SoftmaxDistribution.winProbabilities([100, 50, 10]);
      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
      expect(probs[0], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[2]));
    });

    test('positionProbabilityMatrix da filas que suman 1', () {
      final matrix = SoftmaxDistribution.positionProbabilityMatrix(
        [100, 50, 10],
        simulations: 500,
        seed: 42,
      );
      for (final row in matrix) {
        final sum = row.reduce((a, b) => a + b);
        expect(sum, closeTo(1.0, 0.01));
      }
    });
  });
}
