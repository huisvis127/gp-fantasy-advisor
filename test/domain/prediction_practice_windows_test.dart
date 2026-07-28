import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/driver_context.dart';
import 'package:gp_fantasy_advisor/domain/engine/model_weights.dart';
import 'package:gp_fantasy_advisor/domain/engine/prediction_engine.dart';
import 'package:gp_fantasy_advisor/domain/engine/scoring.dart';

ModelWeights _weights() => ModelWeights.fromJson({
      'feature_weights': {
        'w1_ritmo_carrera': 0.0,
        'w2_ritmo_una_vuelta_historico': 0.0,
        'w3_vuelta_rapida': 1.0,
        'w4_consistencia': 0.0,
        'w5_forma': 0.0,
        'w6_afinidad_circuito': 0.0,
        'w7_forma_equipo': 0.0,
        'w8_riesgo_dnf': 0.0,
      },
      'session_weights_by_objective': {
        'race': {'fp1': .20, 'fp2': .45, 'fp3': .35},
        'sprint': {'fp1': 1.0},
      },
      'practice_blend_by_stage': {
        'fp1_only': {'one_lap': .45, 'pace': .40},
        'friday': {'one_lap': .60, 'pace': .60},
        'saturday': {'one_lap': .72, 'pace': .70},
      },
    });

ScoringTable _scoring() => ScoringTable.fromJson({
      'race': {
        'position_points': {'1': 25},
        'fastest_lap': 5,
        'dnf': -20,
      },
      'qualifying': {
        'position_points': {'1': 10},
      },
      'sprint': {
        'position_points': {'1': 8},
        'dnf': -10,
      },
      'constructor': {'both_cars_q3_bonus': 10},
    });

DriverContext _context(Map<String, double> sessions) => DriverContext(
      driverId: 'driver',
      constructorId: 'team',
      recentRaceFinishPositions: const [10, 10, 10],
      recentOneLapPositions: const [10, 10, 10],
      recentFastestLapGapPercent: const [3],
      circuitHistoryFinishPositions: const [10],
      constructorRecentPoints: const [10],
      driverDnfRateLast2Seasons: .1,
      constructorDnfRateLast2Seasons: .1,
      gridSize: 20,
      sessionAggregates: sessions,
    );

void main() {
  test('los pesos del viernes se reparten solo entre FP1 y FP2', () {
    final weights = _weights();
    final result = weights.sessionWeightsFor(
      isSprint: false,
      availableSessions: {'fp1', 'fp2', 'quali'},
    );

    expect(result.keys, {'fp1', 'fp2'});
    expect(result['fp1'], closeTo(.20 / .65, .0001));
    expect(result['fp2'], closeTo(.45 / .65, .0001));
    expect(result.values.reduce((a, b) => a + b), closeTo(1, .0001));
  });

  test('el sábado redistribuye entre FP1, FP2 y FP3', () {
    final weights = _weights();
    final result = weights.sessionWeightsFor(
      isSprint: false,
      availableSessions: {'fp1', 'fp2', 'fp3'},
    );

    expect(result, {'fp1': .20, 'fp2': .45, 'fp3': .35});
    expect(
      weights.practiceBlendFor(
        kind: 'one_lap',
        availableSessions: result.keys.toSet(),
      ),
      .72,
    );
  });

  test('Qualifying actual no modifica ninguna faceta aunque llegue al motor',
      () {
    final engine = PredictionEngine(_weights(), _scoring());
    final prediction = engine.predictDrivers(
      drivers: [
        _context({
          'onelap:quali': 0,
          'pace:quali': 0,
        }),
      ],
      currentPricesMillions: const {'driver': 10},
      isSprintWeekend: false,
    ).single;

    // El histórico tiene gap 3%, por tanto la faceta permanece en cero.
    expect(prediction.breakdown['vuelta_rapida'], 0);
    expect(prediction.breakdown, isNot(contains('ritmo_clasificacion')));
    expect(prediction.breakdown, contains('ritmo_una_vuelta'));
  });

  test('FP1 mezcla práctica e histórico sin sustituirlo por completo', () {
    final engine = PredictionEngine(_weights(), _scoring());
    final prediction = engine.predictDrivers(
      drivers: [
        _context({
          'onelap:fp1': 0,
          'pace:fp1': 0,
        }),
      ],
      currentPricesMillions: const {'driver': 10},
      isSprintWeekend: false,
    ).single;

    // Histórico = 0, práctica = 100, blend FP1 = 45%.
    expect(prediction.breakdown['vuelta_rapida'], closeTo(45, .001));
  });

  test('los puntos esperados suman clasificación, carrera y Sprint', () {
    final prediction = PredictionEngine(_weights(), _scoring()).predictDrivers(
      drivers: [_context(const {})],
      currentPricesMillions: const {'driver': 10},
      isSprintWeekend: true,
    ).single;

    expect(prediction.pointBreakdown.keys, {
      'clasificacion',
      'carrera',
      'sprint',
    });
    expect(
      prediction.expectedPoints,
      closeTo(
        prediction.pointBreakdown.values.reduce((a, b) => a + b),
        .0001,
      ),
    );
    expect(prediction.pointBreakdown, isNot(contains('adelantamientos')));
  });
}
