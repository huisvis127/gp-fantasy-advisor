import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';

/// Pesos w1..w8 y tabla de pesos por sesión calibrados por backtesting
/// (sección 5.2 del plan, generados por `tools/backtest.py`). Se leen de
/// assets/model_weights.json y, en el futuro, también de la config remota
/// para poder recalibrar sin publicar versión nueva.
class ModelWeights {
  const ModelWeights({
    required this.w1RitmoCarrera,
    required this.w2RitmoClasificacion,
    required this.w3VueltaRapida,
    required this.w4Consistencia,
    required this.w5Forma,
    required this.w6AfinidadCircuito,
    required this.w7FormaEquipo,
    required this.w8RiesgoDnf,
    required this.sessionWeightsAfterFp2,
    required this.sessionWeightsAfterFp3,
  });

  final double w1RitmoCarrera;
  final double w2RitmoClasificacion;
  final double w3VueltaRapida;
  final double w4Consistencia;
  final double w5Forma;
  final double w6AfinidadCircuito;
  final double w7FormaEquipo;
  final double w8RiesgoDnf;

  final Map<String, double> sessionWeightsAfterFp2;
  final Map<String, double> sessionWeightsAfterFp3;

  static Future<ModelWeights> load() async {
    final raw = await rootBundle.loadString(AssetPaths.modelWeights);
    return ModelWeights.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory ModelWeights.fromJson(Map<String, dynamic> json) {
    final fw = json['feature_weights'] as Map<String, dynamic>;
    final sw = json['session_weights_by_objective'] as Map<String, dynamic>;
    Map<String, double> parseSessionWeights(String key) =>
        (sw[key] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));

    return ModelWeights(
      w1RitmoCarrera: (fw['w1_ritmo_carrera'] as num).toDouble(),
      w2RitmoClasificacion: (fw['w2_ritmo_clasificacion'] as num).toDouble(),
      w3VueltaRapida: (fw['w3_vuelta_rapida'] as num).toDouble(),
      w4Consistencia: (fw['w4_consistencia'] as num).toDouble(),
      w5Forma: (fw['w5_forma'] as num).toDouble(),
      w6AfinidadCircuito: (fw['w6_afinidad_circuito'] as num).toDouble(),
      w7FormaEquipo: (fw['w7_forma_equipo'] as num).toDouble(),
      w8RiesgoDnf: (fw['w8_riesgo_dnf'] as num).toDouble(),
      sessionWeightsAfterFp2: parseSessionWeights('race_fp1_fp2'),
      sessionWeightsAfterFp3: parseSessionWeights('race_fp1_fp2_fp3'),
    );
  }

  /// Usa dos modelos distintos: uno al terminar FP2 y otro al terminar FP3.
  /// La clasificación y la sprint quali nunca alimentan la recomendación,
  /// porque el equipo se decide antes de que empiecen.
  Map<String, double> sessionWeightsFor({
    required bool isSprint,
    required Set<String> availableSessions,
  }) {
    final practices = availableSessions.intersection(
      const {'fp1', 'fp2', 'fp3'},
    );
    final base = practices.contains('fp3')
        ? sessionWeightsAfterFp3
        : sessionWeightsAfterFp2;
    final available = base.keys.where(practices.contains).toList();
    if (available.isEmpty) return {};
    final availableTotal =
        available.fold<double>(0, (sum, k) => sum + base[k]!);
    if (availableTotal == 0) return {};
    return {
      for (final k in available) k: base[k]! / availableTotal,
    };
  }
}
