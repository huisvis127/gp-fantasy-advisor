import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engine/isolate_runner.dart';
import '../domain/engine/team_optimizer.dart';
import '../domain/models/my_team.dart';
import '../domain/models/prediction.dart';
import '../domain/models/race.dart';
import '../domain/engine/driver_context.dart';
import 'fantasy_standings_provider.dart';
import 'providers.dart';
import 'selected_gp.dart';
import 'scoring_json_provider.dart';
import 'sync_status.dart';
import 'user_weights.dart';
import 'weekend_provider.dart';

export 'selected_gp.dart';
export 'sync_status.dart';
export 'user_weights.dart';
export 'weekend_provider.dart';

/// Próximo GP real por calendario (independiente del seleccionado).
final nextRaceProvider = FutureProvider<Race?>((ref) async {
  ref.watch(syncControllerProvider);
  final repo = ref.watch(dataRepositoryProvider);
  final season = ref.watch(currentSeasonProvider);
  return repo.nextRace(season);
});

/// ¿Los precios que mostramos son estimados (derivados de la clasificación)
/// o reales de la API de F1 Fantasy?
final pricesAreEstimatedProvider = FutureProvider<bool>((ref) async {
  ref.watch(syncControllerProvider);
  final repo = ref.watch(dataRepositoryProvider);
  return !(await repo.hasRealPrices());
});

/// Predicciones de pilotos para el GP SELECCIONADO, con los pesos elegidos
/// por el usuario (sliders). Recalcula al cambiar GP o pesos.
final driverPredictionsProvider = FutureProvider<List<AssetPrediction>>((ref) async {
  final race = await ref.watch(selectedRaceProvider.future);
  if (race == null) return ref.watch(fallbackDriverPredictionsProvider.future);

  final repo = ref.watch(dataRepositoryProvider);
  final weights = await ref.watch(effectiveWeightsProvider.future);
  final scoringJson = await ref.watch(scoringJsonProvider.future);
  var contexts = await repo.buildDriverContexts(race);
  if (contexts.isEmpty) return ref.watch(fallbackDriverPredictionsProvider.future);

  // Predicción por etapas: si hay sesiones del finde (OpenF1), se inyectan
  // los gaps por sesión en los contextos y el motor los mezcla según la
  // tabla de pesos por sesión (docs/PLAN_PREDICCION_SESIONES.md).
  final weekend = await ref.watch(weekendDataProvider.future);
  if (!weekend.isEmpty) {
    contexts = contexts.map((c) {
      final aggregates = weekend.byDriverId[c.driverId];
      if (aggregates == null) return c;
      return DriverContext(
        driverId: c.driverId,
        constructorId: c.constructorId,
        recentRaceFinishPositions: c.recentRaceFinishPositions,
        recentQualifyingPositions: c.recentQualifyingPositions,
        recentFastestLapGapPercent: c.recentFastestLapGapPercent,
        circuitHistoryFinishPositions: c.circuitHistoryFinishPositions,
        constructorRecentPoints: c.constructorRecentPoints,
        driverDnfRateLast2Seasons: c.driverDnfRateLast2Seasons,
        constructorDnfRateLast2Seasons: c.constructorDnfRateLast2Seasons,
        gridSize: c.gridSize,
        sessionAggregates: aggregates,
      );
    }).toList();
  }

  // Precios: los reales de la API si se sincronizaron; si no, la estimación
  // por clasificación (fantasy_standings_provider). La UI avisa cuando son
  // estimados (pricesAreEstimatedProvider).
  final catalog = await ref.watch(fantasyAssetNameProvider.future);
  final prices = <String, double>{};
  for (final ctx in contexts) {
    final dbPrice = await repo.currentPrice(ctx.driverId, isConstructor: false);
    prices[ctx.driverId] = dbPrice ?? catalog[ctx.driverId]?.priceMillions ?? 15.0;
  }

  final predictions = await PredictionIsolateRunner.predictDrivers(
    weights: weights,
    scoringJson: scoringJson,
    drivers: contexts,
    currentPricesMillions: prices,
    isSprintWeekend: race.hasSprint,
  );
  return predictions.isEmpty ? ref.watch(fallbackDriverPredictionsProvider.future) : predictions;
});

/// Predicciones de constructores derivadas del mismo motor: suma de los
/// E[puntos] de sus pilotos (así los sliders también las recalculan),
/// con el precio del constructor del catálogo/API.
final engineConstructorPredictionsProvider =
    FutureProvider<List<AssetPrediction>>((ref) async {
  final race = await ref.watch(selectedRaceProvider.future);
  final driverPreds = await ref.watch(driverPredictionsProvider.future);
  final catalog = await ref.watch(fantasyAssetNameProvider.future);
  final repo = ref.watch(dataRepositoryProvider);

  if (race == null || driverPreds.isEmpty) {
    return ref.watch(constructorPredictionsProvider.future);
  }

  // Agrupar pilotos por constructor usando el catálogo de standings
  // (id piloto -> nombre de equipo) y el mapa de constructores.
  final constructorInfos = (await ref.watch(fantasyConstructorAssetInfoProvider.future));
  final driversByTeamName = <String, List<AssetPrediction>>{};
  for (final pred in driverPreds) {
    final teamName = catalog[pred.assetId]?.teamName ?? '';
    if (teamName.isEmpty) continue;
    driversByTeamName.putIfAbsent(teamName, () => []).add(pred);
  }

  final result = <AssetPrediction>[];
  for (final info in constructorInfos) {
    final teamDrivers = driversByTeamName[info.name] ?? const <AssetPrediction>[];
    if (teamDrivers.isEmpty) {
      result.add(info.toPrediction());
      continue;
    }
    teamDrivers.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final top2 = teamDrivers.take(2).toList();
    final sumPoints = top2.fold<double>(0, (sum, p) => sum + p.expectedPoints);
    // Bonus esperado de constructor (ambos en Q3, etc.): aproximación
    // proporcional a la prob. de top-10 conjunta de sus 2 pilotos.
    final bothTop10 = top2.length == 2
        ? top2[0].top10Probability * top2[1].top10Probability
        : 0.0;
    final expected = sumPoints + bothTop10 * 10;
    final dbPrice = await repo.currentPrice(info.id, isConstructor: true);
    result.add(AssetPrediction(
      assetId: info.id,
      expectedPoints: expected,
      winProbability: top2.first.winProbability,
      podiumProbability: top2.first.podiumProbability,
      top10Probability: bothTop10,
      priceMillions: dbPrice ?? info.priceMillions,
      breakdown: {
        for (final p in top2) p.assetId: p.expectedPoints,
      },
    ));
  }
  result.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
  return result;
});

final myTeamProvider = AsyncNotifierProvider<MyTeamNotifier, MyTeam?>(MyTeamNotifier.new);

class MyTeamNotifier extends AsyncNotifier<MyTeam?> {
  @override
  Future<MyTeam?> build() async {
    final repo = ref.watch(dataRepositoryProvider);
    return repo.loadMyTeam();
  }

  Future<void> save(MyTeam team) async {
    final repo = ref.read(dataRepositoryProvider);
    await repo.saveMyTeam(team);
    state = AsyncData(team);
  }
}

final teamOptimizerProvider = Provider<TeamOptimizer>((ref) => const TeamOptimizer());

final optimalTeamProvider = FutureProvider.family<TeamCombo, TeamPriority>((ref, priority) async {
  final driverPredictions = await ref.watch(driverPredictionsProvider.future);
  final constructorPredictions =
      await ref.watch(engineConstructorPredictionsProvider.future);
  if (driverPredictions.isEmpty || constructorPredictions.isEmpty) {
    return const TeamCombo(
      driverIds: [],
      constructorIds: [],
      totalCostMillions: 0,
      totalExpectedPoints: 0,
    );
  }
  final optimizer = ref.watch(teamOptimizerProvider);
  return optimizer.findOptimalTeam(
    driverPredictions: driverPredictions,
    constructorPredictions: constructorPredictions,
    totalBudgetMillions: 100,
    priority: priority,
  );
});

/// Los 3 mejores planes de cambios para el equipo del usuario.
final transferPlansProvider = FutureProvider<List<TransferPlan>>((ref) async {
  final team = await ref.watch(myTeamProvider.future);
  if (team == null || !team.isComplete) return const <TransferPlan>[];
  final driverPredictions = await ref.watch(driverPredictionsProvider.future);
  final constructorPredictions =
      await ref.watch(engineConstructorPredictionsProvider.future);
  if (driverPredictions.isEmpty || constructorPredictions.isEmpty) {
    return const <TransferPlan>[];
  }
  final optimizer = ref.watch(teamOptimizerProvider);
  final plans = optimizer.suggestTransfers(
    currentDriverIds: team.driverIds,
    currentConstructorIds: team.constructorIds,
    driverPredictions: driverPredictions,
    constructorPredictions: constructorPredictions,
    remainingBudgetMillions: team.remainingBudgetMillions,
  );
  plans.sort((a, b) => b.netExpectedGain.compareTo(a.netExpectedGain));
  return plans.take(3).toList();
});
