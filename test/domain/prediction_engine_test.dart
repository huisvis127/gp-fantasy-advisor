import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/driver_context.dart';
import 'package:gp_fantasy_advisor/domain/engine/model_weights.dart';
import 'package:gp_fantasy_advisor/domain/engine/prediction_engine.dart';
import 'package:gp_fantasy_advisor/domain/engine/scoring.dart';

const _weights = ModelWeights(
  w1RitmoCarrera: .2,
  w2RitmoClasificacion: .3,
  w3VueltaRapida: .2,
  w4Consistencia: .05,
  w5Forma: .05,
  w6AfinidadCircuito: .05,
  w7FormaEquipo: .1,
  w8RiesgoDnf: .05,
  sessionWeightsAfterFp2: {'fp1': .5, 'fp2': .5},
  sessionWeightsAfterFp3: {'fp1': .4, 'fp2': .2, 'fp3': .4},
);

Map<String, dynamic> _scoringJson() => {
  'race': {
    'position_points': {'1': 25},
    'fastest_lap': 10,
    'dnf': -20,
  },
  'qualifying': {
    'position_points': {'1': 10},
  },
  'sprint': {
    'position_points': {'1': 8},
    'fastest_lap': 5,
    'dnf': -10,
  },
  'constructor': {'both_cars_q3_bonus': 10},
};

DriverContext _driver({double driverDnf = 0, double constructorDnf = 0}) =>
    DriverContext(
      driverId: 'd1',
      constructorId: 'c1',
      recentRaceFinishPositions: [1, 1, 1, 1],
      recentQualifyingPositions: [1, 1, 1, 1],
      recentFastestLapGapPercent: [0],
      circuitHistoryFinishPositions: [1],
      constructorRecentPoints: [40],
      driverDnfRateLast2Seasons: driverDnf,
      constructorDnfRateLast2Seasons: constructorDnf,
      gridSize: 1,
    );

void main() {
  test('suma clasificación al pronóstico del fin de semana', () {
    final engine = PredictionEngine(
      _weights,
      ScoringTable.fromJson(_scoringJson()),
    );
    final result = engine
        .predictDrivers(
          drivers: [_driver()],
          currentPricesMillions: const {'d1': 20},
          isSprintWeekend: false,
        )
        .single;

    expect(result.expectedPoints, closeTo(36.5, .01));
  });

  test('añade el resultado de Sprint en los fines de semana Sprint', () {
    final engine = PredictionEngine(
      _weights,
      ScoringTable.fromJson(_scoringJson()),
    );
    final regular = engine
        .predictDrivers(
          drivers: [_driver()],
          currentPricesMillions: const {'d1': 20},
          isSprintWeekend: false,
        )
        .single
        .expectedPoints;
    final sprint = engine
        .predictDrivers(
          drivers: [_driver()],
          currentPricesMillions: const {'d1': 20},
          isSprintWeekend: true,
        )
        .single
        .expectedPoints;

    expect(sprint - regular, closeTo(8.75, .001));
  });

  test('combina riesgo de DNF del piloto y del constructor', () {
    final engine = PredictionEngine(
      _weights,
      ScoringTable.fromJson(_scoringJson()),
    );
    final noRisk = engine
        .predictDrivers(
          drivers: [_driver()],
          currentPricesMillions: const {'d1': 20},
          isSprintWeekend: false,
        )
        .single
        .expectedPoints;
    final withTeamRisk = engine
        .predictDrivers(
          drivers: [_driver(constructorDnf: .5)],
          currentPricesMillions: const {'d1': 20},
          isSprintWeekend: false,
        )
        .single
        .expectedPoints;

    expect(withTeamRisk, lessThan(noRisk));
  });
}
