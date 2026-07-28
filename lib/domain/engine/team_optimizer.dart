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
    this.boostedDriverId,
  });

  final List<String> driverIds;
  final List<String> constructorIds;
  final double totalCostMillions;
  final double totalExpectedPoints;
  final String? boostedDriverId;
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
        return _optimizeJoint(
          driverPredictions,
          constructorPredictions,
          totalBudgetMillions,
          driverWeight: 1.35,
        );
      case TeamPriority.constructors:
        return _optimizeJoint(
          driverPredictions,
          constructorPredictions,
          totalBudgetMillions,
          constructorWeight: 2.25,
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
    final currentTeamCost = _sumCost(currentDriverIds, driverPredictions) +
        _sumCost(currentConstructorIds, constructorPredictions);
    final currentBoostedDriver =
        recommendBoost(currentDriverIds, driverPredictions);
    final currentTeamPoints = _sumPoints(currentDriverIds, driverPredictions) +
        _sumPoints(currentConstructorIds, constructorPredictions) +
        _pointsFor(currentBoostedDriver, driverPredictions);
    final availableBudget = remainingBudgetMillions + currentTeamCost;

    final plans = <TransferPlan>[];

    // 0 cambios: el equipo actual, de referencia.
    plans.add(TransferPlan(
      transfersOut: const [],
      transfersIn: const [],
      numberOfTransfers: 0,
      extraTransferPenaltyApplied: 0,
      resultingTeam: TeamCombo(
        driverIds: currentDriverIds,
        constructorIds: currentConstructorIds,
        totalCostMillions: currentTeamCost,
        totalExpectedPoints: currentTeamPoints,
        boostedDriverId: currentBoostedDriver,
      ),
      netExpectedGain: 0,
    ));

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
      plans.add(TransferPlan(
        transfersOut: best.transfersOut,
        transfersIn: best.transfersIn,
        numberOfTransfers: n,
        extraTransferPenaltyApplied: penalty,
        resultingTeam: best.combo,
        netExpectedGain: netGain,
      ));
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
    double budget, {
    double driverWeight = 1,
    double constructorWeight = 1,
  }) {
    final driverCombos = _bestPointsPerBudget(
      _combinations(drivers, 5, applyDriverBoost: true),
    );
    final constructorCombos = _combinations(constructors, 2);

    TeamCombo? best;
    double? bestPriorityScore;
    for (final cCombo in constructorCombos) {
      final remaining = budget - cCombo.totalCostMillions;
      if (remaining < 0) continue;
      final bestDrivers = _lookupBestForBudget(driverCombos, remaining);
      if (bestDrivers == null) continue;
      final total =
          bestDrivers.totalExpectedPoints + cCombo.totalExpectedPoints;
      final priorityScore = bestDrivers.totalExpectedPoints * driverWeight +
          cCombo.totalExpectedPoints * constructorWeight;
      if (best == null ||
          bestPriorityScore == null ||
          priorityScore > bestPriorityScore) {
        bestPriorityScore = priorityScore;
        best = TeamCombo(
          driverIds: bestDrivers.driverIds,
          constructorIds: cCombo.driverIds, // reutiliza el mismo campo de ids
          totalCostMillions:
              bestDrivers.totalCostMillions + cCombo.totalCostMillions,
          totalExpectedPoints: total,
          boostedDriverId: bestDrivers.boostedDriverId,
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

  /// Genera todas las combinaciones de tamaño `count` de `pool`.
  List<TeamCombo> _combinations(
    List<AssetPrediction> pool,
    int count, {
    bool applyDriverBoost = false,
  }) {
    final results = <TeamCombo>[];
    void recurse(int start, List<AssetPrediction> chosen) {
      if (chosen.length == count) {
        final boosted = applyDriverBoost
            ? chosen
                .reduce((a, b) => a.expectedPoints >= b.expectedPoints ? a : b)
            : null;
        results.add(TeamCombo(
          driverIds: chosen.map((p) => p.assetId).toList(),
          constructorIds: const [],
          totalCostMillions: chosen.fold(0.0, (s, p) => s + p.priceMillions),
          totalExpectedPoints:
              chosen.fold(0.0, (s, p) => s + p.expectedPoints) +
                  (boosted?.expectedPoints ?? 0),
          boostedDriverId: boosted?.assetId,
        ));
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
      List<TeamCombo> prefixMaxSortedByCost, double budget) {
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

  double _pointsFor(String id, List<AssetPrediction> predictions) {
    for (final prediction in predictions) {
      if (prediction.assetId == id) return prediction.expectedPoints;
    }
    return 0;
  }

  /// Prueba todas las formas de cambiar `swapsAllowed` activos (pilotos o
  /// constructores, indistintamente) y todas las combinaciones de entrada.
  /// Para uno o dos cambios la búsqueda es exhaustiva.
  _BestSwapResult? _bestSwap({
    required List<String> currentDriverIds,
    required List<String> currentConstructorIds,
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double availableBudget,
    required int swapsAllowed,
  }) {
    final driverById = {for (final p in driverPredictions) p.assetId: p};
    final constructorById = {
      for (final p in constructorPredictions) p.assetId: p
    };

    final currentAssets = [
      ...currentDriverIds.map((id) => (id: id, isDriver: true)),
      ...currentConstructorIds.map((id) => (id: id, isDriver: false)),
    ];

    _BestSwapResult? best;

    void recurse(int idx, List<int> outIndices) {
      if (outIndices.length == swapsAllowed) {
        final result = _evaluateSwap(
          currentAssets: currentAssets,
          outIndices: outIndices,
          driverPredictions: driverPredictions,
          constructorPredictions: constructorPredictions,
          driverById: driverById,
          constructorById: constructorById,
          currentDriverIds: currentDriverIds,
          currentConstructorIds: currentConstructorIds,
          availableBudget: availableBudget,
        );
        if (result != null &&
            (best == null ||
                result.totalExpectedPoints > best!.totalExpectedPoints)) {
          best = result;
        }
        return;
      }
      if (idx >= currentAssets.length) return;
      // Con outIndices.length
      recurse(idx + 1, [...outIndices, idx]);
      recurse(idx + 1, outIndices);
    }

    recurse(0, []);
    return best;
  }

  _BestSwapResult? _evaluateSwap({
    required List<({String id, bool isDriver})> currentAssets,
    required List<int> outIndices,
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required Map<String, AssetPrediction> driverById,
    required Map<String, AssetPrediction> constructorById,
    required List<String> currentDriverIds,
    required List<String> currentConstructorIds,
    required double availableBudget,
  }) {
    final remainingDriverIds = [...currentDriverIds];
    final remainingConstructorIds = [...currentConstructorIds];
    final driverTransfersOut = <String>[];
    final constructorTransfersOut = <String>[];

    for (final idx in outIndices) {
      final asset = currentAssets[idx];
      if (asset.isDriver) {
        remainingDriverIds.remove(asset.id);
        driverTransfersOut.add(asset.id);
      } else {
        remainingConstructorIds.remove(asset.id);
        constructorTransfersOut.add(asset.id);
      }
    }

    final driverCandidates = driverPredictions
        .where((p) => !currentDriverIds.contains(p.assetId))
        .toList();
    final constructorCandidates = constructorPredictions
        .where((p) => !currentConstructorIds.contains(p.assetId))
        .toList();
    _BestSwapResult? best;

    for (final incomingDrivers
        in _choose(driverCandidates, driverTransfersOut.length)) {
      for (final incomingConstructors
          in _choose(constructorCandidates, constructorTransfersOut.length)) {
        final driverIds = [
          ...remainingDriverIds,
          ...incomingDrivers.map((p) => p.assetId),
        ];
        final constructorIds = [
          ...remainingConstructorIds,
          ...incomingConstructors.map((p) => p.assetId),
        ];
        final totalCost = _sumCostFromIds(driverIds, driverById) +
            _sumCostFromIds(constructorIds, constructorById);
        if (totalCost > availableBudget + 0.0001) continue;
        final boostedDriverId = driverIds.reduce((a, b) =>
            (driverById[a]?.expectedPoints ?? 0) >=
                    (driverById[b]?.expectedPoints ?? 0)
                ? a
                : b);
        final totalPoints = _sumPointsFromIds(driverIds, driverById) +
            _sumPointsFromIds(constructorIds, constructorById) +
            (driverById[boostedDriverId]?.expectedPoints ?? 0);
        final result = _BestSwapResult(
          transfersOut: [
            ...driverTransfersOut,
            ...constructorTransfersOut,
          ],
          transfersIn: [
            ...incomingDrivers.map((p) => p.assetId),
            ...incomingConstructors.map((p) => p.assetId),
          ],
          combo: TeamCombo(
            driverIds: driverIds,
            constructorIds: constructorIds,
            totalCostMillions: totalCost,
            totalExpectedPoints: totalPoints,
            boostedDriverId: boostedDriverId,
          ),
        );
        if (best == null ||
            result.totalExpectedPoints > best.totalExpectedPoints) {
          best = result;
        }
      }
    }
    return best;
  }

  List<List<AssetPrediction>> _choose(
    List<AssetPrediction> pool,
    int count,
  ) {
    if (count == 0) return const [<AssetPrediction>[]];
    final output = <List<AssetPrediction>>[];
    void visit(int start, List<AssetPrediction> chosen) {
      if (chosen.length == count) {
        output.add([...chosen]);
        return;
      }
      for (var index = start; index < pool.length; index++) {
        chosen.add(pool[index]);
        visit(index + 1, chosen);
        chosen.removeLast();
      }
    }

    visit(0, []);
    return output;
  }

  double _sumCostFromIds(List<String> ids, Map<String, AssetPrediction> byId) =>
      ids.fold(0.0, (s, id) => s + (byId[id]?.priceMillions ?? 0));

  double _sumPointsFromIds(
          List<String> ids, Map<String, AssetPrediction> byId) =>
      ids.fold(0.0, (s, id) => s + (byId[id]?.expectedPoints ?? 0));
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
