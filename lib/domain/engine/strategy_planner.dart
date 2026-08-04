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

    var driverIds = [...initialTeam.driverIds];
    var constructorIds = [...initialTeam.constructorIds];
    var bank = initialTeam.remainingBudgetMillions;
    final histories = <String, List<int>>{
      for (final entry in officialPointHistory.entries)
        entry.key: [...entry.value.take(2)],
    };
    final prices = <String, double>{};
    final plannedRounds = <PlannedRound>[];
    var totalPoints = 0.0;
    var totalPriceGain = 0.0;

    for (final projection in projections) {
      for (final prediction in [
        ...projection.drivers,
        ...projection.constructors,
      ]) {
        prices.putIfAbsent(prediction.assetId, () => prediction.priceMillions);
      }
      final drivers = projection.drivers
          .map(
            (prediction) => _withPrice(prediction, prices[prediction.assetId]!),
          )
          .toList();
      final constructors = projection.constructors
          .map(
            (prediction) => _withPrice(prediction, prices[prediction.assetId]!),
          )
          .toList();
      final currentAssets = [...driverIds, ...constructorIds];
      final plans = optimizer.suggestTransfers(
        currentDriverIds: driverIds,
        currentConstructorIds: constructorIds,
        driverPredictions: drivers,
        constructorPredictions: constructors,
        remainingBudgetMillions: bank,
      );
      final chosen = plans.isEmpty
          ? null
          : plans.firstWhere(
              (plan) => plan.netExpectedGain > 0,
              orElse: () => plans.first,
            );
      if (chosen == null) continue;

      driverIds = [...chosen.resultingTeam.driverIds];
      constructorIds = [...chosen.resultingTeam.constructorIds];
      final availableBudget =
          _teamCost(currentAssets, [...drivers, ...constructors]) + bank;
      bank = (availableBudget - chosen.resultingTeam.totalCostMillions)
          .clamp(0, double.infinity)
          .toDouble();
      final boostId = optimizer.recommendBoost(driverIds, drivers);
      final boostGain = drivers
          .firstWhere((prediction) => prediction.assetId == boostId)
          .expectedPoints;
      final roundPoints =
          chosen.resultingTeam.totalExpectedPoints +
          boostGain +
          chosen.extraTransferPenaltyApplied;

      var ownedPriceGain = 0.0;
      for (final prediction in [...drivers, ...constructors]) {
        final forecast = priceEngine.forecast(
          prediction: prediction,
          previousPoints: histories[prediction.assetId] ?? const [],
        );
        prices[prediction.assetId] =
            prediction.priceMillions + forecast.projectedDeltaMillions;
        if (driverIds.contains(prediction.assetId) ||
            constructorIds.contains(prediction.assetId)) {
          ownedPriceGain += forecast.projectedDeltaMillions;
        }
        histories[prediction.assetId] = [
          prediction.expectedPoints.round(),
          ...(histories[prediction.assetId] ?? const []).take(1),
        ];
      }
      totalPoints += roundPoints;
      totalPriceGain += ownedPriceGain;
      final projectedValue =
          bank +
          driverIds.fold<double>(0, (sum, id) => sum + (prices[id] ?? 0)) +
          constructorIds.fold<double>(0, (sum, id) => sum + (prices[id] ?? 0));
      plannedRounds.add(
        PlannedRound(
          projection: projection,
          driverIds: List.unmodifiable(driverIds),
          constructorIds: List.unmodifiable(constructorIds),
          transfersOut: List.unmodifiable(chosen.transfersOut),
          transfersIn: List.unmodifiable(chosen.transfersIn),
          transferPenalty: chosen.extraTransferPenaltyApplied,
          boostedDriverId: boostId,
          expectedPoints: roundPoints,
          projectedTeamValueMillions: projectedValue,
          projectedPriceGainMillions: ownedPriceGain,
        ),
      );
    }

    return MultiRoundPlan(
      rounds: List.unmodifiable(plannedRounds),
      totalExpectedPoints: totalPoints,
      totalProjectedPriceGainMillions: totalPriceGain,
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
