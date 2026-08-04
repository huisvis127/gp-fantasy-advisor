import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine/model_weights.dart';

/// Pesos del modelo ajustables por el usuario con sliders (queja directa de
/// Luis: "no tiene pesos para elegir... como el ritmo, la constancia, la
/// vuelta rápida"). Mismo comportamiento que los sliders de la app de
/// referencia: los pesos suman 100% y al subir uno bajan los demás
/// proporcionalmente. Se persisten en el dispositivo y hay botón de
/// "restaurar calibrados" (valores de assets/model_weights.json).

const kWeightKeys = [
  'ritmo_carrera',
  'ritmo_clasificacion',
  'vuelta_rapida',
  'consistencia',
  'forma',
  'afinidad_circuito',
  'forma_equipo',
  'riesgo_dnf',
];

const kWeightLabels = {
  'ritmo_carrera': 'Ritmo de carrera',
  'ritmo_clasificacion': 'Clasificación',
  'vuelta_rapida': 'Vuelta rápida',
  'consistencia': 'Consistencia',
  'forma': 'Forma (tendencia)',
  'afinidad_circuito': 'Afinidad al circuito',
  'forma_equipo': 'Forma del equipo',
  'riesgo_dnf': 'Riesgo de abandono',
};

/// Los 4 pesos "de aficionado" (los que cualquiera entiende, equivalentes a
/// los 3 de la app de referencia + clasificación). En modo Aficionado solo
/// se tocan estos; los avanzados quedan preconfigurados con su valor
/// calibrado y el reparto se hace solo dentro del grupo principal.
const kMainWeightKeys = [
  'ritmo_carrera',
  'ritmo_clasificacion',
  'vuelta_rapida',
  'consistencia',
];

const kAdvancedWeightKeys = [
  'forma',
  'afinidad_circuito',
  'forma_equipo',
  'riesgo_dnf',
];

const _prefsKey = 'user_model_weights_v1';
const _modePrefsKey = 'user_weights_mode_v1';

/// Modo de la interfaz de pesos: Aficionado (4 sliders, avanzados fijos)
/// o Profi (los 8 sliders).
enum WeightsMode { aficionado, profi }

class WeightsModeNotifier extends Notifier<WeightsMode> {
  @override
  WeightsMode build() {
    _load();
    return WeightsMode.aficionado;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_modePrefsKey);
      if (raw == WeightsMode.profi.name) state = WeightsMode.profi;
    } catch (_) {}
  }

  Future<void> set(WeightsMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modePrefsKey, mode.name);
    } catch (_) {}
  }
}

final weightsModeProvider =
    NotifierProvider<WeightsModeNotifier, WeightsMode>(WeightsModeNotifier.new);

class UserWeightsNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    _load();
    return defaultPercentages();
  }

  /// Valores calibrados por defecto (model_weights.json), en % que suman 100.
  /// Recalibrados el 05/07/2026 con el mini-backtest de 2026 (ver
  /// docs/backtest_mini_2026.md): la vuelta única (clasificación + vuelta
  /// rápida) domina; los avanzados aportan poco en muestra corta pero se
  /// mantienen con peso pequeño.
  static Map<String, double> defaultPercentages() {
    return {
      'ritmo_carrera': 20,
      'ritmo_clasificacion': 32,
      'vuelta_rapida': 24,
      'consistencia': 10,
      'forma': 4,
      'afinidad_circuito': 4,
      'forma_equipo': 4,
      'riesgo_dnf': 2,
    };
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      if (kWeightKeys.every(decoded.containsKey)) {
        state = decoded;
      }
    } catch (_) {
      // Preferencias corruptas: se mantienen los valores por defecto.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state));
    } catch (_) {
      // Si no se puede persistir, los pesos siguen valiendo esta sesión.
    }
  }

  /// Fija el peso de `key` a `value` y reparte la diferencia entre los demás
  /// proporcionalmente para que la suma siga siendo 100 (mismo comportamiento
  /// que los sliders de la referencia).
  ///
  /// Si `rebalanceWithin` no es null (modo Aficionado), el reparto se hace
  /// SOLO dentro de ese grupo: los pesos de fuera del grupo no se tocan y el
  /// grupo conserva su porcentaje total.
  void setWeight(String key, double value, {List<String>? rebalanceWithin}) {
    final group = rebalanceWithin ?? kWeightKeys;
    final others = group.where((k) => k != key).toList();
    if (others.isEmpty) return;

    final outsideTotal = kWeightKeys
        .where((k) => !group.contains(k))
        .fold<double>(0, (sum, k) => sum + (state[k] ?? 0));
    final groupTotal = 100.0 - outsideTotal;
    final clamped = value.clamp(0.0, groupTotal);
    final currentOthersTotal =
        others.fold<double>(0, (sum, k) => sum + (state[k] ?? 0));
    final targetOthersTotal = groupTotal - clamped;

    final next = Map<String, double>.from(state);
    next[key] = clamped;
    if (currentOthersTotal <= 0) {
      // Reparto uniforme si el resto del grupo estaba a cero.
      for (final k in others) {
        next[k] = targetOthersTotal / others.length;
      }
    } else {
      for (final k in others) {
        next[k] = (state[k] ?? 0) / currentOthersTotal * targetOthersTotal;
      }
    }
    state = next;
    _save();
  }

  void reset() {
    state = defaultPercentages();
    _save();
  }
}

final userWeightsProvider =
    NotifierProvider<UserWeightsNotifier, Map<String, double>>(
        UserWeightsNotifier.new);

/// `ModelWeights` efectivos: la estructura calibrada del asset, con los
/// pesos w1..w8 sustituidos por los porcentajes elegidos por el usuario.
final effectiveWeightsProvider = FutureProvider<ModelWeights>((ref) async {
  final base = await ModelWeights.load();
  final pct = ref.watch(userWeightsProvider);
  double w(String key) => (pct[key] ?? 0) / 100.0;
  return ModelWeights(
    w1RitmoCarrera: w('ritmo_carrera'),
    w2RitmoClasificacion: w('ritmo_clasificacion'),
    w3VueltaRapida: w('vuelta_rapida'),
    w4Consistencia: w('consistencia'),
    w5Forma: w('forma'),
    w6AfinidadCircuito: w('afinidad_circuito'),
    w7FormaEquipo: w('forma_equipo'),
    w8RiesgoDnf: w('riesgo_dnf'),
    sessionWeightsAfterFp2: base.sessionWeightsAfterFp2,
    sessionWeightsAfterFp3: base.sessionWeightsAfterFp3,
  );
});
