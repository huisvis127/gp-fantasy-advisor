import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/engine/isolate_runner.dart';
import '../domain/engine/team_optimizer.dart';
import '../domain/engine/price_forecast_engine.dart';
import '../domain/engine/strategy_planner.dart';
import '../domain/engine/decision_review_engine.dart';
import '../domain/models/my_team.dart';
import '../domain/models/prediction.dart';
import '../domain/models/price_forecast.dart';
import '../domain/models/live_fantasy.dart';
import '../domain/models/race.dart';
import '../domain/models/strategy_plan.dart';
import '../domain/models/decision_review.dart';
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
final driverPredictionsProvider = FutureProvider<List<AssetPrediction>>((
  ref,
) async {
  final race = await ref.watch(selectedRaceProvider.future);
  if (race == null) return ref.watch(fallbackDriverPredictionsProvider.future);

  final repo = ref.watch(dataRepositoryProvider);
  final weights = await ref.watch(effectiveWeightsProvider.future);
  final scoringJson = await ref.watch(scoringJsonProvider.future);
  var contexts = await repo.buildDriverContexts(race);
  if (contexts.isEmpty) {
    return ref.watch(fallbackDriverPredictionsProvider.future);
  }

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
    prices[ctx.driverId] =
        dbPrice ?? catalog[ctx.driverId]?.priceMillions ?? 15.0;
  }

  final predictions = await PredictionIsolateRunner.predictDrivers(
    weights: weights,
    scoringJson: scoringJson,
    drivers: contexts,
    currentPricesMillions: prices,
    isSprintWeekend: race.hasSprint,
  );
  return predictions.isEmpty
      ? ref.watch(fallbackDriverPredictionsProvider.future)
      : predictions;
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
      final constructorInfos = (await ref.watch(
        fantasyConstructorAssetInfoProvider.future,
      ));
      final driversByTeamName = <String, List<AssetPrediction>>{};
      for (final pred in driverPreds) {
        final teamName = catalog[pred.assetId]?.teamName ?? '';
        if (teamName.isEmpty) continue;
        driversByTeamName.putIfAbsent(teamName, () => []).add(pred);
      }

      final result = <AssetPrediction>[];
      for (final info in constructorInfos) {
        final teamDrivers =
            driversByTeamName[info.name] ?? const <AssetPrediction>[];
        if (teamDrivers.isEmpty) {
          result.add(info.toPrediction());
          continue;
        }
        teamDrivers.sort(
          (a, b) => b.expectedPoints.compareTo(a.expectedPoints),
        );
        final top2 = teamDrivers.take(2).toList();
        final sumPoints = top2.fold<double>(
          0,
          (sum, p) => sum + p.expectedPoints,
        );
        // Bonus esperado de constructor (ambos en Q3, etc.): aproximación
        // proporcional a la prob. de top-10 conjunta de sus 2 pilotos.
        final bothTop10 = top2.length == 2
            ? top2[0].top10Probability * top2[1].top10Probability
            : 0.0;
        final expected = sumPoints + bothTop10 * 10;
        final dbPrice = await repo.currentPrice(info.id, isConstructor: true);
        result.add(
          AssetPrediction(
            assetId: info.id,
            expectedPoints: expected,
            winProbability: top2.first.winProbability,
            podiumProbability: top2.first.podiumProbability,
            top10Probability: bothTop10,
            priceMillions: dbPrice ?? info.priceMillions,
            breakdown: {for (final p in top2) p.assetId: p.expectedPoints},
          ),
        );
      }
      result.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
      return result;
    });

typedef RaceKey = ({int season, int round});

/// Predicción pre-fin de semana para cualquier carrera. Es independiente del
/// selector visual y permite preparar varias jornadas sin mutar la pantalla.
final planningDriverPredictionsProvider =
    FutureProvider.family<List<AssetPrediction>, RaceKey>((ref, key) async {
      final repo = ref.watch(dataRepositoryProvider);
      final races = await repo.allRaces(key.season);
      final race = races.where((item) => item.round == key.round).firstOrNull;
      if (race == null) return const [];
      final contexts = await repo.buildDriverContexts(race);
      if (contexts.isEmpty) return const [];
      final weights = await ref.watch(effectiveWeightsProvider.future);
      final scoringJson = await ref.watch(scoringJsonProvider.future);
      final catalog = await ref.watch(fantasyAssetNameProvider.future);
      final prices = <String, double>{};
      for (final context in contexts) {
        final dbPrice = await repo.currentPrice(
          context.driverId,
          isConstructor: false,
        );
        prices[context.driverId] =
            dbPrice ?? catalog[context.driverId]?.priceMillions ?? 15;
      }
      return PredictionIsolateRunner.predictDrivers(
        weights: weights,
        scoringJson: scoringJson,
        drivers: contexts,
        currentPricesMillions: prices,
        isSprintWeekend: race.hasSprint,
      );
    });

final planningConstructorPredictionsProvider =
    FutureProvider.family<List<AssetPrediction>, RaceKey>((ref, key) async {
      final drivers = await ref.watch(
        planningDriverPredictionsProvider(key).future,
      );
      if (drivers.isEmpty) return const [];
      return _buildConstructorPredictions(ref, drivers);
    });

Future<List<AssetPrediction>> _buildConstructorPredictions(
  Ref ref,
  List<AssetPrediction> drivers,
) async {
  final catalog = await ref.watch(fantasyAssetNameProvider.future);
  final repo = ref.watch(dataRepositoryProvider);
  final infos = await ref.watch(fantasyConstructorAssetInfoProvider.future);
  final driversByTeam = <String, List<AssetPrediction>>{};
  for (final prediction in drivers) {
    final team = catalog[prediction.assetId]?.teamName ?? '';
    if (team.isNotEmpty) {
      driversByTeam.putIfAbsent(team, () => []).add(prediction);
    }
  }
  final result = <AssetPrediction>[];
  for (final info in infos) {
    final teamDrivers = [...(driversByTeam[info.name] ?? const [])]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    if (teamDrivers.isEmpty) {
      result.add(info.toPrediction());
      continue;
    }
    final top2 = teamDrivers.take(2).toList();
    final bothTop10 = top2.length == 2
        ? top2[0].top10Probability * top2[1].top10Probability
        : 0.0;
    final expected =
        top2.fold<double>(
          0,
          (sum, prediction) => sum + prediction.expectedPoints,
        ) +
        bothTop10 * 10;
    final price = await repo.currentPrice(info.id, isConstructor: true);
    result.add(
      AssetPrediction(
        assetId: info.id,
        expectedPoints: expected,
        winProbability: top2.first.winProbability,
        podiumProbability: top2.first.podiumProbability,
        top10Probability: bothTop10,
        priceMillions: price ?? info.priceMillions,
        breakdown: {
          for (final prediction in top2)
            prediction.assetId: prediction.expectedPoints,
        },
      ),
    );
  }
  result.sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
  return result;
}

final myTeamProvider = AsyncNotifierProvider<MyTeamNotifier, MyTeam?>(
  MyTeamNotifier.new,
);

class MyTeamNotifier extends AsyncNotifier<MyTeam?> {
  @override
  Future<MyTeam?> build() async {
    final repo = ref.watch(dataRepositoryProvider);
    return repo.loadMyTeam();
  }

  Future<void> save(MyTeam team) async {
    final repo = ref.read(dataRepositoryProvider);
    final race = await ref.read(selectedRaceProvider.future);
    final officialRound = ref.read(liveFantasyProvider).valueOrNull;
    await repo.saveMyTeam(
      team,
      season: officialRound?.season ?? race?.season,
      round: officialRound?.round ?? race?.round,
    );
    state = AsyncData(team);
  }
}

final teamOptimizerProvider = Provider<TeamOptimizer>(
  (ref) => const TeamOptimizer(),
);

/// Centro de decisión inspirado en el calculador de MotoGP: plantilla base,
/// mejor plan con 1 cambio, mejor plan con 2 y techo absoluto del GP.
final teamDecisionCenterProvider = FutureProvider<TeamDecisionCenter?>((
  ref,
) async {
  final team = await ref.watch(myTeamProvider.future);
  if (team == null || !team.isComplete) return null;
  final drivers = await ref.watch(driverPredictionsProvider.future);
  final constructors = await ref.watch(
    engineConstructorPredictionsProvider.future,
  );
  if (drivers.isEmpty || constructors.isEmpty) return null;
  return ref
      .watch(teamOptimizerProvider)
      .buildDecisionCenter(
        currentDriverIds: team.driverIds,
        currentConstructorIds: team.constructorIds,
        driverPredictions: drivers,
        constructorPredictions: constructors,
        remainingBudgetMillions: team.remainingBudgetMillions,
      );
});

final priceForecastEngineProvider = Provider<PriceForecastEngine>(
  (ref) => const PriceForecastEngine(),
);

/// Mercado proyectado con las dos últimas puntuaciones oficiales y la
/// predicción de la jornada seleccionada como tercer término de la ventana.
final priceForecastsProvider = FutureProvider<List<PriceForecast>>((ref) async {
  final repo = ref.watch(dataRepositoryProvider);
  final engine = ref.watch(priceForecastEngineProvider);
  final drivers = await ref.watch(driverPredictionsProvider.future);
  final constructors = await ref.watch(
    engineConstructorPredictionsProvider.future,
  );
  final forecasts = <PriceForecast>[];
  for (final prediction in [...drivers, ...constructors]) {
    final isConstructor = constructors.any(
      (item) => item.assetId == prediction.assetId,
    );
    final previousPoints = await repo.recentFantasyPoints(
      prediction.assetId,
      isConstructor: isConstructor,
      limit: 2,
    );
    forecasts.add(
      engine.forecast(prediction: prediction, previousPoints: previousPoints),
    );
  }
  forecasts.sort((a, b) {
    final rise = b.riseProbability.compareTo(a.riseProbability);
    return rise != 0
        ? rise
        : b.projectedDeltaMillions.compareTo(a.projectedDeltaMillions);
  });
  return forecasts;
});

final strategyPlannerProvider = Provider<StrategyPlanner>(
  (ref) => const StrategyPlanner(),
);

final roundProjectionsProvider = FutureProvider<List<RoundProjection>>((
  ref,
) async {
  final selected = await ref.watch(selectedRaceProvider.future);
  if (selected == null) return const [];
  final races = await ref.watch(seasonRacesProvider.future);
  final start = races.indexWhere((race) => race.round == selected.round);
  if (start < 0) return const [];
  final upcoming = races.skip(start).take(3).toList();
  final projections = <RoundProjection>[];
  for (var index = 0; index < upcoming.length; index++) {
    final race = upcoming[index];
    final key = (season: race.season, round: race.round);
    final drivers = index == 0
        ? await ref.watch(driverPredictionsProvider.future)
        : await ref.watch(planningDriverPredictionsProvider(key).future);
    final constructors = index == 0
        ? await ref.watch(engineConstructorPredictionsProvider.future)
        : await ref.watch(planningConstructorPredictionsProvider(key).future);
    if (drivers.isEmpty || constructors.isEmpty) continue;
    projections.add(
      RoundProjection(
        season: race.season,
        round: race.round,
        raceName: race.raceName,
        hasSprint: race.hasSprint,
        drivers: drivers,
        constructors: constructors,
      ),
    );
  }
  return projections;
});

final strategyPlanProvider = FutureProvider<MultiRoundPlan>((ref) async {
  final team = await ref.watch(myTeamProvider.future);
  if (team == null || !team.isComplete) {
    return const MultiRoundPlan(
      rounds: [],
      totalExpectedPoints: 0,
      totalProjectedPriceGainMillions: 0,
    );
  }
  final projections = await ref.watch(roundProjectionsProvider.future);
  if (projections.isEmpty) {
    return const MultiRoundPlan(
      rounds: [],
      totalExpectedPoints: 0,
      totalProjectedPriceGainMillions: 0,
    );
  }
  final repo = ref.watch(dataRepositoryProvider);
  final history = <String, List<int>>{};
  for (final prediction in [
    ...projections.first.drivers,
    ...projections.first.constructors,
  ]) {
    final isConstructor = projections.first.constructors.any(
      (item) => item.assetId == prediction.assetId,
    );
    history[prediction.assetId] = await repo.recentFantasyPoints(
      prediction.assetId,
      isConstructor: isConstructor,
      limit: 2,
    );
  }
  return ref
      .watch(strategyPlannerProvider)
      .buildPlan(
        initialTeam: team,
        projections: projections,
        officialPointHistory: history,
      );
});

final chipAdviceProvider = FutureProvider<List<ChipAdvice>>((ref) async {
  final team = await ref.watch(myTeamProvider.future);
  if (team == null) return const [];
  final plan = await ref.watch(strategyPlanProvider.future);
  return ref.watch(strategyPlannerProvider).adviseChips(team: team, plan: plan);
});

/// Feed oficial provisional. En directo se actualiza cada 20 segundos; fuera
/// de sesión se refresca con menor frecuencia para no malgastar red/batería.
final liveFantasyProvider = StreamProvider<LiveFantasySnapshot>((ref) async* {
  final api = ref.watch(fantasyApiProvider);
  final season = ref.watch(currentSeasonProvider);
  while (true) {
    final snapshot = await api.getLiveSnapshot(season);
    yield snapshot;
    await Future<void>.delayed(
      snapshot.isLive
          ? const Duration(seconds: 20)
          : const Duration(minutes: 5),
    );
  }
});

final latestDecisionReviewProvider = FutureProvider<DecisionReview?>((
  ref,
) async {
  ref.watch(syncControllerProvider);
  final repo = ref.watch(dataRepositoryProvider);
  final snapshots = await repo.teamSnapshots();
  for (final snapshot in snapshots) {
    final points = await repo.fantasyPointsForRound(
      snapshot.season,
      snapshot.round,
    );
    if (points.isEmpty) continue;
    final prices = await repo.pricesForRound(snapshot.season, snapshot.round);
    final priceById = {
      for (final row in prices) row.assetId: row.priceMillions,
    };
    final actualDrivers = <AssetPrediction>[];
    final actualConstructors = <AssetPrediction>[];
    for (final row in points) {
      final prediction = AssetPrediction(
        assetId: row.assetId,
        expectedPoints: row.points.toDouble(),
        winProbability: 0,
        podiumProbability: 0,
        top10Probability: 0,
        priceMillions: priceById[row.assetId] ?? 0,
        breakdown: const {},
      );
      if (row.assetType == 'constructor') {
        actualConstructors.add(prediction);
      } else {
        actualDrivers.add(prediction);
      }
    }
    if (actualDrivers.length < 5 || actualConstructors.length < 2) continue;
    final races = await repo.allRaces(snapshot.season);
    final race = races
        .where((item) => item.round == snapshot.round)
        .firstOrNull;
    final team = MyTeam(
      driverIds: snapshot.driverIdsCsv
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList(),
      constructorIds: snapshot.constructorIdsCsv
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList(),
      remainingBudgetMillions: snapshot.remainingBudgetMillions,
      boostedDriverId: snapshot.boostedDriverId,
      chipsUsed: snapshot.chipsUsedCsv
          .split(',')
          .where((chip) => chip.isNotEmpty)
          .toSet(),
    );
    if (!team.isComplete) continue;
    return const DecisionReviewEngine().review(
      season: snapshot.season,
      round: snapshot.round,
      raceName: race?.raceName ?? 'Jornada ${snapshot.round}',
      team: team,
      actualDrivers: actualDrivers,
      actualConstructors: actualConstructors,
    );
  }
  return null;
});

final optimalTeamProvider = FutureProvider.family<TeamCombo, TeamPriority>((
  ref,
  priority,
) async {
  final driverPredictions = await ref.watch(driverPredictionsProvider.future);
  final constructorPredictions = await ref.watch(
    engineConstructorPredictionsProvider.future,
  );
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
  final constructorPredictions = await ref.watch(
    engineConstructorPredictionsProvider.future,
  );
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
