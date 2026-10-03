import 'dart:isolate';

import '../models/prediction.dart';
import 'driver_context.dart';
import 'model_weights.dart';
import 'prediction_engine.dart';
import 'scoring.dart';

/// Corre el motor de predicción (y, en team_optimizer.dart, la enumeración
/// con poda) en un Isolate para no congelar la UI, tal y como pide la
/// sección 4 del plan ("Sin backend. Todo el cálculo... en un Isolate").
///
/// `Isolate.run` (Dart 3+) crea, ejecuta y cierra el isolate por nosotros;
/// no hace falta gestionar puertos a mano para este caso de uso puntual.
class PredictionIsolateRunner {
  static Future<List<AssetPrediction>> predictDrivers({
    required ModelWeights weights,
    required Map<String, dynamic> scoringJson,
    required List<DriverContext> drivers,
    required Map<String, double> currentPricesMillions,
    required bool isSprintWeekend,
  }) {
    return Isolate.run(() {
      final engine =
          PredictionEngine(weights, ScoringTable.fromJson(scoringJson));
      return engine.predictDrivers(
        drivers: drivers,
        currentPricesMillions: currentPricesMillions,
        isSprintWeekend: isSprintWeekend,
      );
    });
  }
}
