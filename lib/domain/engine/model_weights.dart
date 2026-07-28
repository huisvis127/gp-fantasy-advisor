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
    required this.w2RitmoUnaVueltaHistorico,
    required this.w3VueltaRapida,
    required this.w4Consistencia,
    required this.w5Forma,
    required this.w6AfinidadCircuito,
    required this.w7FormaEquipo,
    required this.w8RiesgoDnf,
    required this.sessionWeightsRace,
    required this.sessionWeightsSprint,
    required this.practiceBlendByStage,
  });

  final double w1RitmoCarrera;
  final double w2RitmoUnaVueltaHistorico;
  final double w3VueltaRapida;
  final double w4Consistencia;
  final double w5Forma;
  final double w6AfinidadCircuito;
  final double w7FormaEquipo;
  final double w8RiesgoDnf;

  final Map<String, double> sessionWeightsRace;
  final Map<String, double> sessionWeightsSprint;
  final Map<String, Map<String, double>> practiceBlendByStage;

  static Future<ModelWeights> load() async {
    final raw = await rootBundle.loadString(AssetPaths.modelWeights);
    return ModelWeights.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory ModelWeights.fromJson(Map<String, dynamic> json) {
    final fw = json['feature_weights'] as Map<String, dynamic>;
    final sw = json['session_weights_by_objective'] as Map<String, dynamic>;
    final blend =
        json['practice_blend_by_stage'] as Map<String, dynamic>? ?? const {};
    Map<String, double> parseSessionWeights(String key) =>
        (sw[key] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));

    return ModelWeights(
      w1RitmoCarrera: (fw['w1_ritmo_carrera'] as num).toDouble(),
      w2RitmoUnaVueltaHistorico: (fw['w2_ritmo_una_vuelta_historico'] ??
              fw['w2_ritmo_clasificacion'] as num)
          .toDouble(),
      w3VueltaRapida: (fw['w3_vuelta_rapida'] as num).toDouble(),
      w4Consistencia: (fw['w4_consistencia'] as num).toDouble(),
      w5Forma: (fw['w5_forma'] as num).toDouble(),
      w6AfinidadCircuito: (fw['w6_afinidad_circuito'] as num).toDouble(),
      w7FormaEquipo: (fw['w7_forma_equipo'] as num).toDouble(),
      w8RiesgoDnf: (fw['w8_riesgo_dnf'] as num).toDouble(),
      sessionWeightsRace: parseSessionWeights('race'),
      sessionWeightsSprint: parseSessionWeights('sprint'),
      practiceBlendByStage: blend.map(
        (stage, values) => MapEntry(
          stage,
          (values as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        ),
      ),
    );
  }

  /// Pesos por sesión repartiendo proporcionalmente el peso de una sesión
  /// que falta entre las demás (sección 5.1: "si una sesión no existe su
  /// peso se reparte proporcionalmente entre las demás").
  Map<String, double> sessionWeightsFor({
    required bool isSprint,
    required Set<String> availableSessions,
  }) {
    final base = isSprint ? sessionWeightsSprint : sessionWeightsRace;
    final available = base.keys.where(availableSessions.contains).toList();
    if (available.isEmpty) return {};
    final availableTotal =
        available.fold<double>(0, (sum, k) => sum + base[k]!);
    if (availableTotal == 0) return {};
    return {
      for (final k in available) k: base[k]! / availableTotal,
    };
  }

  /// Porcentaje de la faceta que procede de los libres del GP actual.
  /// El resto conserva el histórico previo al GP.
  double practiceBlendFor({
    required String kind,
    required Set<String> availableSessions,
  }) {
    if (availableSessions.isEmpty) return 0;
    final stage = availableSessions.contains('fp3')
        ? 'saturday'
        : availableSessions.contains('fp2')
            ? 'friday'
            : 'fp1_only';
    return (practiceBlendByStage[stage]?[kind] ?? 0).clamp(0.0, 1.0);
  }
}
