import 'dart:isolate';

import '../models/my_team.dart';
import '../models/prediction.dart';
import '../models/strategy_plan.dart';
import '../models/decision_review.dart';
import 'team_optimizer.dart';
import 'strategy_planner.dart';
import 'decision_review_engine.dart';

/// Only one optimization worker at a time: keep the UI responsive and avoid
/// competing searches exhausting a phone's CPU and memory.
class OptimizationIsolateRunner {
  static Future<void> _tail = Future<void>.value();

  static Future<T> _run<T>(T Function() computation) {
    final result = _tail.then((_) => Isolate.run(computation));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  static Future<TeamCombo> optimal({
    required TeamOptimizer optimizer,
    required List<AssetPrediction> drivers,
    required List<AssetPrediction> constructors,
    required TeamPriority priority,
  }) => _run(
    () => optimizer.findOptimalTeam(
      driverPredictions: drivers,
      constructorPredictions: constructors,
      totalBudgetMillions: 100,
      priority: priority,
    ),
  );

  static Future<TeamDecisionCenter> decisionCenter({
    required TeamOptimizer optimizer,
    required MyTeam team,
    required List<AssetPrediction> drivers,
    required List<AssetPrediction> constructors,
  }) => _run(
    () => optimizer.buildDecisionCenter(
      currentDriverIds: team.driverIds,
      currentConstructorIds: team.constructorIds,
      currentBoostedDriverId: team.boostedDriverId,
      driverPredictions: drivers,
      constructorPredictions: constructors,
      remainingBudgetMillions: team.remainingBudgetMillions,
    ),
  );

  static Future<List<TransferPlan>> transfers({
    required TeamOptimizer optimizer,
    required MyTeam team,
    required List<AssetPrediction> drivers,
    required List<AssetPrediction> constructors,
  }) => _run(
    () => optimizer.suggestTransfers(
      currentDriverIds: team.driverIds,
      currentConstructorIds: team.constructorIds,
      currentBoostedDriverId: team.boostedDriverId,
      driverPredictions: drivers,
      constructorPredictions: constructors,
      remainingBudgetMillions: team.remainingBudgetMillions,
    ),
  );

  static Future<MultiRoundPlan> strategy({
    required StrategyPlanner planner,
    required MyTeam team,
    required List<RoundProjection> projections,
    required Map<String, List<int>> history,
  }) => _run(
    () => planner.buildPlan(
      initialTeam: team,
      projections: projections,
      officialPointHistory: history,
    ),
  );

  static Future<DecisionReview> review({
    required int season,
    required int round,
    required String raceName,
    required MyTeam team,
    required List<AssetPrediction> drivers,
    required List<AssetPrediction> constructors,
  }) => _run(
    () => const DecisionReviewEngine().review(
      season: season,
      round: round,
      raceName: raceName,
      team: team,
      actualDrivers: drivers,
      actualConstructors: constructors,
    ),
  );
}
