import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/data_repository.dart';
import '../domain/engine/isolate_runner.dart';
import '../domain/engine/team_optimizer.dart';
import '../domain/models/my_team.dart';
import '../domain/models/prediction.dart';
import '../domain/models/race.dart';
import '../domain/engine/driver_context.dart';
import '../domain/engine/fantasy_budget_ledger.dart';
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

/// Calendario detallado del GP seleccionado. Jolpica incluye aquí los
/// horarios de libres, sprint y clasificación que no se guardan en caché.
final selectedRaceScheduleProvider = FutureProvider<Race?>((ref) async {
  final selected = await ref.watch(selectedRaceProvider.future);
  if (selected == null) return null;
  if (!shouldLoadWeekendData(selected, DateTime.now())) return selected;
  try {
    final calendar =
        await ref.watch(jolpicaApiProvider).getSeasonCalendar(selected.season);
    final matches = calendar.where((race) => race.round == selected.round);
    return matches.isEmpty ? selected : matches.first;
  } catch (_) {
    return selected;
  }
});

final circuitWinnersProvider = FutureProvider<List<CircuitWinner>>((ref) async {
  ref.watch(syncControllerProvider);
  final race = await ref.watch(selectedRaceProvider.future);
  if (race == null) return const [];
  return ref.watch(dataRepositoryProvider).circuitWinners(race);
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
final driverPredictionsProvider =
    FutureProvider<List<AssetPrediction>>((ref) async {
  final race = await ref.watch(selectedRaceProvider.future);
  if (race == null) return ref.watch(fallbackDriverPredictionsProvider.future);

  final repo = ref.watch(dataRepositoryProvider);
  final weights = await ref.watch(effectiveWeightsProvider.future);
  final requestedWindow = ref.watch(predictionDataWindowProvider);
  final scoringJson = await ref.watch(scoringJsonProvider.future);
  var contexts = await repo.buildDriverContexts(race);
  if (contexts.isEmpty) {
    return ref.watch(fallbackDriverPredictionsProvider.future);
  }

  // Predicción por etapas: si hay sesiones del finde (OpenF1), se inyectan
  // los gaps por sesión en los contextos y el motor los mezcla según la
  // tabla de pesos por sesión (docs/PLAN_PREDICCION_SESIONES.md).
  final weekend = await ref.watch(weekendDataProvider.future);
  final activeWindow = weekend.resolveWindow(requestedWindow);
  final stagedWeekend = weekend.byDriverIdFor(activeWindow);
  if (stagedWeekend.isNotEmpty) {
    contexts = contexts.map((c) {
      final aggregates = stagedWeekend[c.driverId];
      if (aggregates == null) return c;
      return DriverContext(
        driverId: c.driverId,
        constructorId: c.constructorId,
        recentRaceFinishPositions: c.recentRaceFinishPositions,
        recentOneLapPositions: c.recentOneLapPositions,
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
  final roundPrices = await repo.fantasyPricesForRound(race.season, race.round);
  final prices = <String, double>{};
  for (final ctx in contexts) {
    final dbPrice = await repo.currentPrice(ctx.driverId, isConstructor: false);
    prices[ctx.driverId] = roundPrices[ctx.driverId] ??
        dbPrice ??
        catalog[ctx.driverId]?.priceMillions ??
        15.0;
  }

  final predictions = await PredictionIsolateRunner.predictDrivers(
    weights: weights,
    scoringJson: scoringJson,
    drivers: contexts,
    currentPricesMillions: prices,
    isSprintWeekend: race.hasSprint,
  );
  if (predictions.isEmpty) {
    return ref.watch(fallbackDriverPredictionsProvider.future);
  }
  // El total ya representa E[clasificación + carrera + Sprint]. No se mezcla
  // con la media Fantasy anterior: el backtest 2025 mostró que arrastrar los
  // extras históricos (adelantamientos, DOTD, etc.) empeora la correlación.
  return predictions;
});

/// Predicciones de constructores derivadas del mismo motor: suma de los
/// E[puntos] de sus pilotos (así los sliders también las recalculan),
/// con el precio del constructor del catálogo/API.
final engineConstructorPredictionsProvider =
    FutureProvider<List<AssetPrediction>>((ref) async {
  final race = await ref.watch(selectedRaceProvider.future);
  final driverPreds = await ref.watch(driverPredictionsProvider.future);
  final repo = ref.watch(dataRepositoryProvider);

  if (race == null || driverPreds.isEmpty) {
    return ref.watch(constructorPredictionsProvider.future);
  }

  // Agrupar pilotos por constructor usando el catálogo de standings
  // (id piloto -> nombre de equipo) y el mapa de constructores.
  final contexts = await repo.buildDriverContexts(race);
  final constructorByDriver = <String, String>{
    for (final context in contexts) context.driverId: context.constructorId,
  };
  final constructorInfos =
      await ref.watch(fantasyConstructorAssetInfoProvider.future);
  final infoById = {for (final info in constructorInfos) info.id: info};
  final driversByConstructor = <String, List<AssetPrediction>>{};
  for (final pred in driverPreds) {
    final constructorId = constructorByDriver[pred.assetId];
    if (constructorId == null || constructorId.isEmpty) continue;
    driversByConstructor.putIfAbsent(constructorId, () => []).add(pred);
  }

  final result = <AssetPrediction>[];
  final roundPrices = await repo.fantasyPricesForRound(race.season, race.round);
  for (final entry in driversByConstructor.entries) {
    final constructorId = entry.key;
    final info = infoById[constructorId];
    final teamDrivers = entry.value;
    teamDrivers.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final top2 = teamDrivers.take(2).toList();
    final sumPoints = top2.fold<double>(0, (sum, p) => sum + p.expectedPoints);
    // Bonus esperado de constructor (ambos en Q3, etc.): aproximación
    // proporcional a la prob. de top-10 conjunta de sus 2 pilotos.
    final bothTop10 = top2.length == 2
        ? top2[0].top10Probability * top2[1].top10Probability
        : 0.0;
    final modeledExpected = sumPoints + bothTop10 * 10;
    final dbPrice = await repo.currentPrice(constructorId, isConstructor: true);
    result.add(AssetPrediction(
      assetId: constructorId,
      expectedPoints: modeledExpected,
      winProbability: top2.first.winProbability,
      podiumProbability: top2.first.podiumProbability,
      top10Probability: bothTop10,
      priceMillions:
          roundPrices[constructorId] ?? dbPrice ?? info?.priceMillions ?? 12.0,
      breakdown: {
        for (final p in top2) p.assetId: p.expectedPoints,
      },
      pointBreakdown: {
        'pilotos': sumPoints,
        'bonus_clasificacion': bothTop10 * 10,
      },
    ));
  }
  result.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
  return result;
});

final myTeamProvider =
    AsyncNotifierProvider<MyTeamNotifier, MyTeam?>(MyTeamNotifier.new);

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

  Future<void> clear() async {
    final repo = ref.read(dataRepositoryProvider);
    await repo.clearUserData();
    state = const AsyncData(null);
  }
}

final teamOptimizerProvider =
    Provider<TeamOptimizer>((ref) => const TeamOptimizer());

final myTeamPurchasingPowerProvider = FutureProvider<double?>((ref) async {
  final team = await ref.watch(myTeamProvider.future);
  if (team == null || !team.isComplete) return null;

  final drivers = await ref.watch(driverPredictionsProvider.future);
  final constructors =
      await ref.watch(engineConstructorPredictionsProvider.future);
  final prices = <String, double>{
    for (final prediction in [...drivers, ...constructors])
      prediction.assetId: prediction.priceMillions,
  };
  final assetIds = [...team.driverIds, ...team.constructorIds];
  if (assetIds.any((id) => !prices.containsKey(id))) return null;

  final teamValue = assetIds.fold<double>(
    0,
    (sum, id) => sum + prices[id]!,
  );
  return teamValue + team.remainingBudgetMillions;
});

typedef OptimalTeamRequest = ({TeamPriority priority, double budgetMillions});

final optimalTeamProvider =
    FutureProvider.family<TeamCombo, OptimalTeamRequest>((ref, request) async {
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
    totalBudgetMillions: request.budgetMillions,
    priority: request.priority,
  );
});

class FantasySimulationRound {
  const FantasySimulationRound({
    required this.race,
    required this.team,
    required this.transfersOut,
    required this.transfersIn,
    required this.points,
    required this.cumulativePoints,
    required this.budgetMillions,
    required this.budgetChangeMillions,
    required this.teamValueMillions,
    required this.cashMillions,
    required this.hasOfficialPrices,
  });

  final Race race;
  final TeamCombo team;
  final List<String> transfersOut;
  final List<String> transfersIn;
  final double points;
  final double cumulativePoints;
  final double budgetMillions;
  final double budgetChangeMillions;
  final double teamValueMillions;
  final double cashMillions;
  final bool hasOfficialPrices;
}

class FantasySeasonSimulation {
  const FantasySeasonSimulation({required this.rounds});
  final List<FantasySimulationRound> rounds;

  double get totalPoints => rounds.isEmpty ? 0 : rounds.last.cumulativePoints;
  TeamCombo? get currentTeam => rounds.isEmpty ? null : rounds.last.team;
}

/// Reconstruye la estrategia de la app desde la primera carrera. Antes de cada
/// GP conserva el equipo o ejecuta hasta dos cambios gratuitos cuando mejoran
/// la proyección. No aplica ningún chip.
final fantasySeasonSimulationProvider =
    FutureProvider<FantasySeasonSimulation>((ref) async {
  ref.watch(syncControllerProvider);
  final repo = ref.watch(dataRepositoryProvider);
  final season = ref.watch(currentSeasonProvider);
  final weights = await ref.watch(effectiveWeightsProvider.future);
  final scoringJson = await ref.watch(scoringJsonProvider.future);
  final catalog = await ref.watch(fantasyAssetNameProvider.future);
  final races = (await repo.allRaces(season))
      .where((race) => race.date.isBefore(DateTime.now()))
      .toList()
    ..sort((a, b) => a.round.compareTo(b.round));
  final optimizer = ref.watch(teamOptimizerProvider);
  final output = <FantasySimulationRound>[];
  TeamCombo? currentTeam;
  var cumulative = 0.0;
  FantasyBudgetLedger? budgetLedger;

  for (final race in races) {
    final results = await repo.raceResults(season, race.round);
    final contexts = await repo.buildDriverContexts(race);
    if (results.isEmpty || contexts.isEmpty) continue;

    final roundPrices = await repo.fantasyPricesForRound(season, race.round);
    final prices = <String, double>{
      for (final context in contexts)
        context.driverId: roundPrices[context.driverId] ??
            catalog[context.driverId]?.priceMillions ??
            15,
    };
    final rawDriverPredictions = await PredictionIsolateRunner.predictDrivers(
      weights: weights,
      scoringJson: scoringJson,
      drivers: contexts,
      currentPricesMillions: prices,
      isSprintWeekend: race.hasSprint,
    );
    final driverPredictions = rawDriverPredictions;
    final contextByDriver = {
      for (final context in contexts) context.driverId: context
    };
    final byConstructor = <String, List<AssetPrediction>>{};
    for (final prediction in driverPredictions) {
      final constructorId = contextByDriver[prediction.assetId]?.constructorId;
      if (constructorId != null && constructorId.isNotEmpty) {
        byConstructor.putIfAbsent(constructorId, () => []).add(prediction);
      }
    }
    final constructorPredictions = [
      for (final group in byConstructor.entries)
        AssetPrediction(
          assetId: group.key,
          expectedPoints:
              group.value.fold<double>(0, (sum, p) => sum + p.expectedPoints),
          winProbability: group.value.fold<double>(0,
              (best, p) => p.winProbability > best ? p.winProbability : best),
          podiumProbability: group.value.fold<double>(
              0,
              (best, p) =>
                  p.podiumProbability > best ? p.podiumProbability : best),
          top10Probability: 1,
          priceMillions:
              roundPrices[group.key] ?? catalog[group.key]?.priceMillions ?? 12,
          breakdown: const {},
          pointBreakdown: {
            'pilotos':
                group.value.fold<double>(0, (sum, p) => sum + p.expectedPoints),
          },
        ),
    ];
    if (driverPredictions.length < 5 || constructorPredictions.length < 2) {
      continue;
    }

    var transfersOut = const <String>[];
    var transfersIn = const <String>[];
    var budgetBefore = 100.0;
    if (currentTeam == null) {
      currentTeam = optimizer.findOptimalTeam(
        driverPredictions: driverPredictions,
        constructorPredictions: constructorPredictions,
        totalBudgetMillions: 100,
      );
      budgetLedger = FantasyBudgetLedger.initial(
        startingBudgetMillions: 100,
        teamCostMillions: currentTeam.totalCostMillions,
      );
    } else {
      final driverById = {
        for (final prediction in driverPredictions)
          prediction.assetId: prediction
      };
      final constructorById = {
        for (final prediction in constructorPredictions)
          prediction.assetId: prediction
      };
      final currentCost = currentTeam.driverIds.fold<double>(
              0, (sum, id) => sum + (driverById[id]?.priceMillions ?? 0)) +
          currentTeam.constructorIds.fold<double>(
              0, (sum, id) => sum + (constructorById[id]?.priceMillions ?? 0));
      budgetBefore = budgetLedger!.purchasingPower(currentCost);
      final plans = optimizer.suggestTransfers(
        currentDriverIds: currentTeam.driverIds,
        currentConstructorIds: currentTeam.constructorIds,
        driverPredictions: driverPredictions,
        constructorPredictions: constructorPredictions,
        remainingBudgetMillions: budgetLedger.cashMillions,
        maxTransfersToConsider: 2,
      );
      final best = plans.isEmpty ? null : plans.first;
      if (best != null && best.netExpectedGain > 0) {
        currentTeam = best.resultingTeam;
        transfersOut = best.transfersOut;
        transfersIn = best.transfersIn;
      } else {
        TransferPlan? unchanged;
        for (final plan in plans) {
          if (plan.numberOfTransfers == 0) {
            unchanged = plan;
            break;
          }
        }
        if (unchanged != null) currentTeam = unchanged.resultingTeam;
      }
      budgetLedger = budgetLedger.afterTransfers(
        currentTeamValueMillions: currentCost,
        resultingTeamCostMillions: currentTeam.totalCostMillions,
      );
    }
    final team = currentTeam;
    if (team.driverIds.length != 5 || team.constructorIds.length != 2) {
      continue;
    }

    final qualifying = await repo.qualifyingResults(season, race.round);
    final qualifyingByDriver = {
      for (final result in qualifying) result.driverId: result
    };
    final raceRules = Map<String, dynamic>.from(scoringJson['race'] as Map);
    final qualifyingRules =
        Map<String, dynamic>.from(scoringJson['qualifying'] as Map);
    final constructorRules =
        Map<String, dynamic>.from(scoringJson['constructor'] as Map);
    final racePositions =
        Map<String, dynamic>.from(raceRules['position_points'] as Map);
    final qualifyingPositions =
        Map<String, dynamic>.from(qualifyingRules['position_points'] as Map);
    final driverScores = <String, double>{};
    final constructorByDriver = <String, String>{};
    for (final result in results) {
      constructorByDriver[result.driverId] = result.constructorId;
      var score = (racePositions[result.finishPosition?.toString()] as num?)
              ?.toDouble() ??
          (result.finishPosition == null
              ? (raceRules['dnf'] as num?)?.toDouble() ?? -20
              : 0);
      score += (qualifyingPositions[qualifyingByDriver[result.driverId]
                  ?.position
                  .toString()] as num?)
              ?.toDouble() ??
          0;
      if (result.finishPosition != null && result.gridPosition > 0) {
        score += (result.gridPosition - result.finishPosition!) *
            ((raceRules['positions_gained_per_place'] as num?)?.toDouble() ??
                1);
      }
      if (result.fastestLap) {
        score += (raceRules['fastest_lap'] as num?)?.toDouble() ?? 0;
      }
      driverScores[result.driverId] = score;
    }
    final constructorScores = <String, double>{};
    for (final id in team.constructorIds) {
      final drivers = constructorByDriver.entries
          .where((entry) => entry.value == id)
          .map((entry) => entry.key)
          .toList();
      var score =
          drivers.fold<double>(0, (sum, id) => sum + (driverScores[id] ?? 0));
      if (drivers
              .where((id) => (qualifyingByDriver[id]?.position ?? 99) <= 10)
              .length >=
          2) {
        score +=
            (constructorRules['both_cars_q3_bonus'] as num?)?.toDouble() ?? 0;
      }
      constructorScores[id] = score;
    }
    var roundPoints = team.driverIds
            .fold<double>(0, (sum, id) => sum + (driverScores[id] ?? 0)) +
        team.constructorIds
            .fold<double>(0, (sum, id) => sum + (constructorScores[id] ?? 0)) +
        (driverScores[team.boostedDriverId] ?? 0);
    final officialPoints = await repo.fantasyPointsForRound(season, race.round);
    final teamAssets = [...team.driverIds, ...team.constructorIds];
    if (teamAssets.every(officialPoints.containsKey) &&
        team.boostedDriverId != null) {
      roundPoints = teamAssets.fold<double>(
            0,
            (sum, id) => sum + officialPoints[id]!,
          ) +
          officialPoints[team.boostedDriverId]!;
    }
    cumulative += roundPoints;
    final previousBudget = output.isEmpty ? 100.0 : output.last.budgetMillions;
    final teamAssetIds = [...team.driverIds, ...team.constructorIds];
    output.add(FantasySimulationRound(
      race: race,
      team: team,
      transfersOut: transfersOut,
      transfersIn: transfersIn,
      points: roundPoints,
      cumulativePoints: cumulative,
      budgetMillions: budgetBefore,
      budgetChangeMillions: budgetBefore - previousBudget,
      teamValueMillions: team.totalCostMillions,
      cashMillions: budgetLedger.cashMillions,
      hasOfficialPrices: teamAssetIds.every(roundPrices.containsKey),
    ));
  }
  return FantasySeasonSimulation(rounds: output);
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
