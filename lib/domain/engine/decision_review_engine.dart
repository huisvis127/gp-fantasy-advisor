import '../models/decision_review.dart';
import '../models/my_team.dart';
import '../models/prediction.dart';
import 'team_optimizer.dart';

class DecisionReviewEngine {
  const DecisionReviewEngine({this.optimizer = const TeamOptimizer()});

  final TeamOptimizer optimizer;

  DecisionReview review({
    required int season,
    required int round,
    required String raceName,
    required MyTeam team,
    required List<AssetPrediction> actualDrivers,
    required List<AssetPrediction> actualConstructors,
  }) {
    final all = {
      for (final item in [...actualDrivers, ...actualConstructors])
        item.assetId: item,
    };
    final ownedIds = [...team.driverIds, ...team.constructorIds];
    final basePoints = ownedIds.fold<double>(
      0,
      (sum, id) => sum + (all[id]?.expectedPoints ?? 0),
    );
    final boostImpact = team.boostedDriverId == null
        ? 0.0
        : all[team.boostedDriverId]?.expectedPoints ?? 0;
    final teamPoints = basePoints + boostImpact;
    final teamValue =
        ownedIds.fold<double>(
          0,
          (sum, id) => sum + (all[id]?.priceMillions ?? 0),
        ) +
        team.remainingBudgetMillions;
    final optimal = optimizer.findOptimalTeam(
      driverPredictions: actualDrivers,
      constructorPredictions: actualConstructors,
      totalBudgetMillions: teamValue,
    );
    final optimalBoost = optimal.driverIds.isEmpty
        ? 0.0
        : optimal.driverIds
              .map((id) => all[id]?.expectedPoints ?? 0)
              .reduce((a, b) => a >= b ? a : b);
    final optimalPoints = optimal.totalExpectedPoints + optimalBoost;
    final owned =
        ownedIds.map((id) => all[id]).whereType<AssetPrediction>().toList()
          ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final best = owned.first;
    final worst = owned.last;
    return DecisionReview(
      season: season,
      round: round,
      raceName: raceName,
      teamPoints: teamPoints,
      optimalPoints: optimalPoints,
      missedPoints: (optimalPoints - teamPoints)
          .clamp(0, double.infinity)
          .toDouble(),
      boostImpact: boostImpact,
      bestAssetId: best.assetId,
      bestAssetPoints: best.expectedPoints,
      worstAssetId: worst.assetId,
      worstAssetPoints: worst.expectedPoints,
    );
  }
}
