import '../models/prediction.dart';

/// Sesgo de presupuesto entre pilotos y constructores (sección 5.3: "Dos
/// modos de recomendación... un simple sesgo del presupuesto asignado a
/// cada grupo antes de optimizar, seleccionable con un toggle").
enum TeamPriority { balanced, drivers, constructors }

class TeamCombo {
  const TeamCombo({
    required this.driverIds,
    required this.constructorIds,
    required this.totalCostMillions,
    required this.totalExpectedPoints,
  });

  final List<String> driverIds;
  final List<String> constructorIds;
  final double totalCostMillions;
  final double totalExpectedPoints;
}

class TransferPlan {
  const TransferPlan({
    required this.transfersOut,
    required this.transfersIn,
    required this.numberOfTransfers,
    required this.extraTransferPenaltyApplied,
    required this.resultingTeam,
    required this.netExpectedGain,
  });

  final List<String> transfersOut;
  final List<String> transfersIn;
  final int numberOfTransfers;
  final int extraTransferPenaltyApplied;
  final TeamCombo resultingTeam;
  final double netExpectedGain;
}

/// Optimizador de equipo (sección 5.3 del plan). Enumeración exhaustiva con
/// poda, corre en Isolate (ver isolate_runner.dart / prediction_engine.dart)
/// porque C(22,5) x C(11,2) ~= 1.45M combinaciones son manejables en
/// milisegundos con la poda por presupuesto de esta implementación
/// (se ordenan las combinaciones de pilotos por coste y se usa un array de
/// "mejor puntuación alcanzable para un presupuesto <= X" en vez de probar
/// las 1.45M parejas una a una).
class TeamOptimizer {
  const TeamOptimizer();

  /// Equipo ideal desde cero, respetando el presupuesto total.
  TeamCombo findOptimalTeam({
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double totalBudgetMillions,
    TeamPriority priority = TeamPriority.balanced,
  }) {
    switch (priority) {
      case TeamPriority.balanced:
        return _optimizeJoint(
          driverPredictions,
          constructorPredictions,
          totalBudgetMillions,
        );
      case TeamPriority.drivers:
        return _optimizeWithSplit(
          driverPredictions,
          constructorPredictions,
          totalBudgetMillions,
          driverBudgetFraction: 0.72,
        );
      case TeamPriority.constructors:
        return _optimizeWithSplit(
          driverPredictions,
          constructorPredictions,
          totalBudgetMillions,
          driverBudgetFraction: 0.55,
        );
    }
  }

  /// Partiendo del equipo importado, evalúa los equipos alcanzables con 0,
  /// 1 y 2 cambios gratis, y opcionalmente un 3er cambio penalizado con
  /// -10 puntos, devolviendo los 3 mejores planes por ganancia neta
  /// (sección 5.3: "Sugerencia de cambios").
  List<TransferPlan> suggestTransfers({
    required List<String> currentDriverIds,
    required List<String> currentConstructorIds,
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double remainingBudgetMillions,
    int maxTransfersToConsider = 3,
    int extraTransferPenalty = -10,
  }) {
    final currentTeamCost =
        _sumCost(currentDriverIds, driverPredictions) +
        _sumCost(currentConstructorIds, constructorPredictions);
    final currentTeamPoints =
        _sumPoints(currentDriverIds, driverPredictions) +
        _sumPoints(currentConstructorIds, constructorPredictions);
    final availableBudget = remainingBudgetMillions + currentTeamCost;

    final plans = <TransferPlan>[];

    // 0 cambios: el equipo actual, de referencia.
    plans.add(
      TransferPlan(
        transfersOut: const [],
        transfersIn: const [],
        numberOfTransfers: 0,
        extraTransferPenaltyApplied: 0,
        resultingTeam: TeamCombo(
          driverIds: currentDriverIds,
          constructorIds: currentConstructorIds,
          totalCostMillions: currentTeamCost,
          totalExpectedPoints: currentTeamPoints,
        ),
        netExpectedGain: 0,
      ),
    );

    for (var n = 1; n <= maxTransfersToConsider; n++) {
      final penalty = n > 2 ? extraTransferPenalty * (n - 2) : 0;
      final best = _bestSwap(
        currentDriverIds: currentDriverIds,
        currentConstructorIds: currentConstructorIds,
        driverPredictions: driverPredictions,
        constructorPredictions: constructorPredictions,
        availableBudget: availableBudget,
        swapsAllowed: n,
      );
      if (best == null) continue;
      final netGain = (best.totalExpectedPoints + penalty) - currentTeamPoints;
      plans.add(
        TransferPlan(
          transfersOut: best.transfersOut,
          transfersIn: best.transfersIn,
          numberOfTransfers: n,
          extraTransferPenaltyApplied: penalty,
          resultingTeam: best.combo,
          netExpectedGain: netGain,
        ),
      );
    }

    plans.sort((a, b) => b.netExpectedGain.compareTo(a.netExpectedGain));
    return plans.take(3).toList();
  }

  /// Piloto óptimo para el boost x2: el de mayor puntuación esperada
  /// dentro del equipo actual (sección 5.3).
  String recommendBoost(
    List<String> driverIds,
    List<AssetPrediction> driverPredictions,
  ) {
    final byId = {for (final p in driverPredictions) p.assetId: p};
    final inTeam = driverIds.map((id) => byId[id]).whereType<AssetPrediction>();
    return inTeam
        .reduce((a, b) => a.expectedPoints >= b.expectedPoints ? a : b)
        .assetId;
  }

  // ---- Implementación ----

  TeamCombo _optimizeJoint(
    List<AssetPrediction> drivers,
    List<AssetPrediction> constructors,
    double budget,
  ) {
    final driverCombos = _bestPointsPerBudget(_combinations(drivers, 5));
    final constructorCombos = _combinations(constructors, 2);

    TeamCombo? best;
    for (final cCombo in constructorCombos) {
      final remaining = budget - cCombo.totalCostMillions;
      if (remaining < 0) continue;
      final bestDrivers = _lookupBestForBudget(driverCombos, remaining);
      if (bestDrivers == null) continue;
      final total =
          bestDrivers.totalExpectedPoints + cCombo.totalExpectedPoints;
      if (best == null || total > best.totalExpectedPoints) {
        best = TeamCombo(
          driverIds: bestDrivers.driverIds,
          constructorIds: cCombo.driverIds, // reutiliza el mismo campo de ids
          totalCostMillions:
              bestDrivers.totalCostMillions + cCombo.totalCostMillions,
          totalExpectedPoints: total,
        );
      }
    }
    return best ??
        const TeamCombo(
          driverIds: [],
          constructorIds: [],
          totalCostMillions: 0,
          totalExpectedPoints: 0,
        );
  }

  TeamCombo _optimizeWithSplit(
    List<AssetPrediction> drivers,
    List<AssetPrediction> constructors,
    double budget, {
    required double driverBudgetFraction,
  }) {
    final driverBudget = budget * driverBudgetFraction;
    final constructorBudget = budget - driverBudget;

    final bestDrivers = _bestSingleGroup(drivers, 5, driverBudget);
    final bestConstructors = _bestSingleGroup(
      constructors,
      2,
      constructorBudget,
    );

    return TeamCombo(
      driverIds: bestDrivers.driverIds,
      constructorIds: bestConstructors.driverIds,
      totalCostMillions:
          bestDrivers.totalCostMillions + bestConstructors.totalCostMillions,
      totalExpectedPoints:
          bestDrivers.totalExpectedPoints +
          bestConstructors.totalExpectedPoints,
    );
  }

  TeamCombo _bestSingleGroup(
    List<AssetPrediction> pool,
    int count,
    double budget,
  ) {
    final combos = _combinations(pool, count);
    TeamCombo? best;
    for (final c in combos) {
      if (c.totalCostMillions > budget) continue;
      if (best == null || c.totalExpectedPoints > best.totalExpectedPoints) {
        best = c;
      }
    }
    return best ??
        const TeamCombo(
          driverIds: [],
          constructorIds: [],
          totalCostMillions: 0,
          totalExpectedPoints: 0,
        );
  }

  /// Genera todas las combinaciones de tamaño `count` de `pool`.
  List<TeamCombo> _combinations(List<AssetPrediction> pool, int count) {
    final results = <TeamCombo>[];
    void recurse(int start, List<AssetPrediction> chosen) {
      if (chosen.length == count) {
        results.add(
          TeamCombo(
            driverIds: chosen.map((p) => p.assetId).toList(),
            constructorIds: const [],
            totalCostMillions: chosen.fold(0.0, (s, p) => s + p.priceMillions),
            totalExpectedPoints: chosen.fold(
              0.0,
              (s, p) => s + p.expectedPoints,
            ),
          ),
        );
        return;
      }
      for (var i = start; i < pool.length; i++) {
        chosen.add(pool[i]);
        recurse(i + 1, chosen);
        chosen.removeLast();
      }
    }

    recurse(0, []);
    return results;
  }

  /// Ordena las combinaciones por coste y precalcula, para cada índice, la
  /// mejor puntuación alcanzable con coste <= al de ese índice (prefix-max).
  /// Permite después, para un presupuesto dado, encontrar la mejor
  /// combinación de pilotos con una búsqueda binaria en vez de recorrer
  /// las ~26k combinaciones por cada combinación de constructores.
  List<TeamCombo> _bestPointsPerBudget(List<TeamCombo> combos) {
    final sorted = [...combos]
      ..sort((a, b) => a.totalCostMillions.compareTo(b.totalCostMillions));
    var runningBest = sorted.isEmpty ? null : sorted.first;
    final prefixed = <TeamCombo>[];
    for (final c in sorted) {
      if (runningBest == null ||
          c.totalExpectedPoints > runningBest.totalExpectedPoints) {
        runningBest = c;
      }
      prefixed.add(runningBest);
    }
    return prefixed; // mismo orden (ascendente por coste) que `sorted`
  }

  TeamCombo? _lookupBestForBudget(
    List<TeamCombo> prefixMaxSortedByCost,
    double budget,
  ) {
    if (prefixMaxSortedByCost.isEmpty) return null;
    // Búsqueda binaria del último índice con coste <= budget.
    var lo = 0;
    var hi = prefixMaxSortedByCost.length - 1;
    var answer = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (prefixMaxSortedByCost[mid].totalCostMillions <= budget) {
        answer = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return answer == -1 ? null : prefixMaxSortedByCost[answer];
  }

  double _sumCost(List<String> ids, List<AssetPrediction> predictions) {
    final byId = {for (final p in predictions) p.assetId: p};
    return ids.fold(0.0, (s, id) => s + (byId[id]?.priceMillions ?? 0));
  }

  double _sumPoints(List<String> ids, List<AssetPrediction> predictions) {
    final byId = {for (final p in predictions) p.assetId: p};
    return ids.fold(0.0, (s, id) => s + (byId[id]?.expectedPoints ?? 0));
  }

  /// Prueba todas las formas de cambiar `swapsAllowed` activos (pilotos o
  /// constructores, indistintamente) del equipo actual por otros mejores,
  /// dentro del presupuesto disponible. Simplificación razonable para v1:
  /// no separa pilotos de constructores al elegir qué N cambiar.
  _BestSwapResult? _bestSwap({
    required List<String> currentDriverIds,
    required List<String> currentConstructorIds,
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double availableBudget,
    required int swapsAllowed,
  }) {
    final currentDrivers = currentDriverIds.toSet();
    final currentConstructors = currentConstructorIds.toSet();
    final driverCombos = _combinations(driverPredictions, 5);
    final constructorCombos = _combinations(constructorPredictions, 2);
    _BestSwapResult? best;
    for (final drivers in driverCombos) {
      final retainedDrivers = drivers.driverIds
          .where(currentDrivers.contains)
          .length;
      final driverChanges = 5 - retainedDrivers;
      if (driverChanges > swapsAllowed) continue;
      for (final constructors in constructorCombos) {
        final retainedConstructors = constructors.driverIds
            .where(currentConstructors.contains)
            .length;
        final changes = driverChanges + 2 - retainedConstructors;
        if (changes != swapsAllowed) continue;
        final cost = drivers.totalCostMillions + constructors.totalCostMillions;
        if (cost > availableBudget + 0.0001) continue;
        final points =
            drivers.totalExpectedPoints + constructors.totalExpectedPoints;
        if (best != null && points <= best.totalExpectedPoints) continue;
        final nextDrivers = drivers.driverIds;
        final nextConstructors = constructors.driverIds;
        best = _BestSwapResult(
          transfersOut: [
            ...currentDriverIds.where((id) => !nextDrivers.contains(id)),
            ...currentConstructorIds.where(
              (id) => !nextConstructors.contains(id),
            ),
          ],
          transfersIn: [
            ...nextDrivers.where((id) => !currentDrivers.contains(id)),
            ...nextConstructors.where(
              (id) => !currentConstructors.contains(id),
            ),
          ],
          combo: TeamCombo(
            driverIds: List.unmodifiable(nextDrivers),
            constructorIds: List.unmodifiable(nextConstructors),
            totalCostMillions: cost,
            totalExpectedPoints: points,
          ),
        );
      }
    }
    return best;
  }
}

class _BestSwapResult {
  _BestSwapResult({
    required this.transfersOut,
    required this.transfersIn,
    required this.combo,
  });

  final List<String> transfersOut;
  final List<String> transfersIn;
  final TeamCombo combo;

  double get totalExpectedPoints => combo.totalExpectedPoints;
}
