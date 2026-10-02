import '../models/my_team.dart';
import '../models/prediction.dart';
import '../models/strategy_plan.dart';
import 'price_forecast_engine.dart';
import 'team_optimizer.dart';

class StrategyPlanner {
  const StrategyPlanner({
    this.optimizer = const TeamOptimizer(),
    this.priceEngine = const PriceForecastEngine(),
  });

  final TeamOptimizer optimizer;
  final PriceForecastEngine priceEngine;

  MultiRoundPlan buildPlan({
    required MyTeam initialTeam,
    required List<RoundProjection> projections,
    Map<String, List<int>> officialPointHistory = const {},
  }) {
    if (!initialTeam.isComplete || projections.isEmpty) {
      return const MultiRoundPlan(
        rounds: [],
        totalExpectedPoints: 0,
        totalProjectedPriceGainMillions: 0,
      );
    }

    final histories = <String, List<int>>{
      for (final entry in officialPointHistory.entries)
        entry.key: [...entry.value.take(2)],
    };
    final initialPrices = <String, double>{};
    for (final projection in projections) {
      for (final prediction in [
        ...projection.drivers,
        ...projection.constructors,
      ]) {
        initialPrices.putIfAbsent(
          prediction.assetId,
          () => prediction.priceMillions,
        );
      }
    }

    var beam = <_PlanState>[
      _PlanState(
        driverIds: [...initialTeam.driverIds],
        constructorIds: [...initialTeam.constructorIds],
        bank: initialTeam.remainingBudgetMillions,
        prices: initialPrices,
        histories: histories,
        rounds: const [],
        totalPoints: 0,
        totalPriceGain: 0,
      ),
    ];

    for (final projection in projections) {
      final expanded = <_PlanState>[];
      for (final state in beam) {
        final drivers = projection.drivers
            .map(
              (prediction) => _withPrice(
                prediction,
                state.prices[prediction.assetId] ?? prediction.priceMillions,
              ),
            )
            .toList();
        final constructors = projection.constructors
            .map(
              (prediction) => _withPrice(
                prediction,
                state.prices[prediction.assetId] ?? prediction.priceMillions,
              ),
            )
            .toList();
        final candidates = optimizer.transferCandidates(
          currentDriverIds: state.driverIds,
          currentConstructorIds: state.constructorIds,
          driverPredictions: drivers,
          constructorPredictions: constructors,
          remainingBudgetMillions: state.bank,
          candidatesPerTransferCount: 2,
        );
        for (final candidate in candidates) {
          final nextDrivers = [...candidate.resultingTeam.driverIds];
          final nextConstructors = [...candidate.resultingTeam.constructorIds];
          if (nextDrivers.isEmpty || nextConstructors.isEmpty) continue;
          final currentAssets = [...state.driverIds, ...state.constructorIds];
          final availableBudget =
              _teamCost(currentAssets, [...drivers, ...constructors]) +
              state.bank;
          final nextBank =
              (availableBudget - candidate.resultingTeam.totalCostMillions)
                  .clamp(0, double.infinity)
                  .toDouble();
          final boostId = optimizer.recommendBoost(nextDrivers, drivers);
          final boostGain = drivers
              .firstWhere((prediction) => prediction.assetId == boostId)
              .expectedPoints;
          final roundPoints =
              candidate.resultingTeam.totalExpectedPoints +
              boostGain +
              candidate.extraTransferPenaltyApplied;

          final nextPrices = {...state.prices};
          final nextHistories = <String, List<int>>{
            for (final entry in state.histories.entries)
              entry.key: [...entry.value],
          };
          var ownedPriceGain = 0.0;
          for (final prediction in [...drivers, ...constructors]) {
            final forecast = priceEngine.forecast(
              prediction: prediction,
              previousPoints: nextHistories[prediction.assetId] ?? const [],
            );
            nextPrices[prediction.assetId] =
                prediction.priceMillions + forecast.projectedDeltaMillions;
            if (nextDrivers.contains(prediction.assetId) ||
                nextConstructors.contains(prediction.assetId)) {
              ownedPriceGain += forecast.projectedDeltaMillions;
            }
            nextHistories[prediction.assetId] = [
              prediction.expectedPoints.round(),
              ...(nextHistories[prediction.assetId] ?? const []).take(1),
            ];
          }
          final projectedValue =
              nextBank +
              nextDrivers.fold<double>(
                0,
                (sum, id) => sum + (nextPrices[id] ?? 0),
              ) +
              nextConstructors.fold<double>(
                0,
                (sum, id) => sum + (nextPrices[id] ?? 0),
              );
          final plannedRound = PlannedRound(
            projection: projection,
            driverIds: List.unmodifiable(nextDrivers),
            constructorIds: List.unmodifiable(nextConstructors),
            transfersOut: List.unmodifiable(candidate.transfersOut),
            transfersIn: List.unmodifiable(candidate.transfersIn),
            transferPenalty: candidate.extraTransferPenaltyApplied,
            boostedDriverId: boostId,
            expectedPoints: roundPoints,
            projectedTeamValueMillions: projectedValue,
            projectedPriceGainMillions: ownedPriceGain,
          );
          expanded.add(
            _PlanState(
              driverIds: nextDrivers,
              constructorIds: nextConstructors,
              bank: nextBank,
              prices: nextPrices,
              histories: nextHistories,
              rounds: [...state.rounds, plannedRound],
              totalPoints: state.totalPoints + roundPoints,
              totalPriceGain: state.totalPriceGain + ownedPriceGain,
            ),
          );
        }
      }
      if (expanded.isEmpty) break;
      final deduplicated = <String, _PlanState>{};
      for (final state in expanded) {
        final drivers = [...state.driverIds]..sort();
        final constructors = [...state.constructorIds]..sort();
        final key =
            '${drivers.join(',')}|${constructors.join(',')}|'
            '${state.bank.toStringAsFixed(2)}';
        final previous = deduplicated[key];
        if (previous == null || state.objective > previous.objective) {
          deduplicated[key] = state;
        }
      }
      beam = deduplicated.values.toList()
        ..sort((a, b) => b.objective.compareTo(a.objective));
      if (beam.length > 4) beam = beam.take(4).toList();
    }

    if (beam.isEmpty) {
      return const MultiRoundPlan(
        rounds: [],
        totalExpectedPoints: 0,
        totalProjectedPriceGainMillions: 0,
      );
    }
    beam.sort((a, b) => b.objective.compareTo(a.objective));
    final best = beam.first;
    return MultiRoundPlan(
      rounds: List.unmodifiable(best.rounds),
      totalExpectedPoints: best.totalPoints,
      totalProjectedPriceGainMillions: best.totalPriceGain,
    );
  }

  List<ChipAdvice> adviseChips({
    required MyTeam team,
    required MultiRoundPlan plan,
  }) {
    if (plan.rounds.isEmpty) return const [];
    final first = plan.rounds.first;
    final used = team.chipsUsed.map((chip) => chip.toLowerCase()).toSet();
    final transferCount = first.transfersIn.length;
    final bestDriver = first.projection.drivers.reduce(
      (a, b) => a.expectedPoints >= b.expectedPoints ? a : b,
    );
    final dnfRisk =
        first.projection.drivers
            .where((prediction) => first.driverIds.contains(prediction.assetId))
            .fold<double>(0, (sum, prediction) {
              return sum + (prediction.breakdown['riesgo_dnf'] ?? 10) / 100;
            }) /
        first.driverIds.length;
    final advice = <ChipAdvice>[
      if (!used.contains('wildcard'))
        ChipAdvice(
          chip: 'Wildcard',
          level: transferCount >= 3
              ? ChipRecommendationLevel.use
              : ChipRecommendationLevel.hold,
          score: (transferCount * 30).clamp(10, 100).toInt(),
          reason: transferCount >= 3
              ? 'El plan necesita $transferCount cambios; evita penalizaciones.'
              : 'El equipo se puede corregir con los cambios gratuitos.',
        ),
      if (!used.contains('limitless'))
        ChipAdvice(
          chip: 'Limitless',
          level: first.projection.hasSprint && bestDriver.expectedPoints >= 25
              ? ChipRecommendationLevel.consider
              : ChipRecommendationLevel.hold,
          score: first.projection.hasSprint ? 65 : 25,
          reason: first.projection.hasSprint
              ? 'Fin de semana Sprint: hay más puntos disponibles.'
              : 'Guárdalo para un Sprint con gran diferencia entre premiums.',
        ),
      if (!used.contains('triple boost'))
        ChipAdvice(
          chip: 'Triple Boost',
          level: bestDriver.expectedPoints >= 30
              ? ChipRecommendationLevel.use
              : bestDriver.expectedPoints >= 24
              ? ChipRecommendationLevel.consider
              : ChipRecommendationLevel.hold,
          score: (bestDriver.expectedPoints * 2.5)
              .round()
              .clamp(10, 100)
              .toInt(),
          reason:
              '${bestDriver.assetId} proyecta ${bestDriver.expectedPoints.toStringAsFixed(1)} puntos.',
        ),
      if (!used.contains('no negative'))
        ChipAdvice(
          chip: 'No Negative',
          level: dnfRisk >= 0.22
              ? ChipRecommendationLevel.consider
              : ChipRecommendationLevel.hold,
          score: (dnfRisk * 300).round().clamp(10, 100).toInt(),
          reason: dnfRisk >= 0.22
              ? 'El riesgo agregado de abandono es elevado.'
              : 'El riesgo actual no justifica gastar el chip.',
        ),
      if (!used.contains('autopilot'))
        const ChipAdvice(
          chip: 'Autopilot',
          level: ChipRecommendationLevel.hold,
          score: 30,
          reason:
              'Úsalo cuando dos pilotos estén muy igualados y haya alta incertidumbre.',
        ),
      if (!used.contains('final fix'))
        const ChipAdvice(
          chip: 'Final Fix',
          level: ChipRecommendationLevel.hold,
          score: 20,
          reason:
              'Resérvalo para una sorpresa de clasificación o una incidencia tras el cierre.',
        ),
    ];
    advice.sort((a, b) => b.score.compareTo(a.score));
    return advice;
  }

  AssetPrediction _withPrice(AssetPrediction prediction, double price) =>
      AssetPrediction(
        assetId: prediction.assetId,
        expectedPoints: prediction.expectedPoints,
        winProbability: prediction.winProbability,
        podiumProbability: prediction.podiumProbability,
        top10Probability: prediction.top10Probability,
        priceMillions: price,
        breakdown: prediction.breakdown,
      );

  double _teamCost(List<String> ids, List<AssetPrediction> predictions) {
    final byId = {
      for (final prediction in predictions) prediction.assetId: prediction,
    };
    return ids.fold<double>(
      0,
      (sum, id) => sum + (byId[id]?.priceMillions ?? 0),
    );
  }
}

class _PlanState {
  const _PlanState({
    required this.driverIds,
    required this.constructorIds,
    required this.bank,
    required this.prices,
    required this.histories,
    required this.rounds,
    required this.totalPoints,
    required this.totalPriceGain,
  });

  final List<String> driverIds;
  final List<String> constructorIds;
  final double bank;
  final Map<String, double> prices;
  final Map<String, List<int>> histories;
  final List<PlannedRound> rounds;
  final double totalPoints;
  final double totalPriceGain;

  /// Un millón adicional se valora como seis puntos dentro del horizonte.
  /// Así se conserva una ruta que construye presupuesto sin permitir que el
  /// valor económico domine a los puntos Fantasy reales.
  double get objective => totalPoints + totalPriceGain * 6;
}
