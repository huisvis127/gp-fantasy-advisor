import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/decision_review_engine.dart';
import 'package:gp_fantasy_advisor/domain/engine/optimization_isolate_runner.dart';
import 'package:gp_fantasy_advisor/domain/engine/strategy_planner.dart';
import 'package:gp_fantasy_advisor/domain/engine/team_optimizer.dart';
import 'package:gp_fantasy_advisor/domain/models/my_team.dart';
import 'package:gp_fantasy_advisor/domain/models/prediction.dart';
import 'package:gp_fantasy_advisor/domain/models/strategy_plan.dart';

AssetPrediction _prediction(String id, double points, double price) =>
    AssetPrediction(
      assetId: id,
      expectedPoints: points,
      winProbability: 0.1,
      podiumProbability: 0.3,
      top10Probability: 0.8,
      priceMillions: price,
      breakdown: const {},
    );

final _drivers = [
  _prediction('d1', 30, 20),
  _prediction('d2', 25, 18),
  _prediction('d3', 20, 15),
  _prediction('d4', 18, 12),
  _prediction('d5', 15, 10),
  _prediction('d6', 35, 19),
];

final _constructors = [
  _prediction('c1', 40, 22),
  _prediction('c2', 30, 18),
  _prediction('c3', 45, 24),
];

const _team = MyTeam(
  driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
  constructorIds: ['c1', 'c2'],
  remainingBudgetMillions: 10,
  boostedDriverId: 'd1',
);

void main() {
  test(
    'delegates optimization results without changing engine output',
    () async {
      const optimizer = TeamOptimizer();
      final directOptimal = optimizer.findOptimalTeam(
        driverPredictions: _drivers,
        constructorPredictions: _constructors,
        totalBudgetMillions: 100,
      );
      final isolatedOptimal = await OptimizationIsolateRunner.optimal(
        optimizer: optimizer,
        drivers: _drivers,
        constructors: _constructors,
        priority: TeamPriority.balanced,
      );
      expect(isolatedOptimal.driverIds, directOptimal.driverIds);
      expect(isolatedOptimal.constructorIds, directOptimal.constructorIds);
      expect(
        isolatedOptimal.totalCostMillions,
        directOptimal.totalCostMillions,
      );
      expect(
        isolatedOptimal.totalExpectedPoints,
        directOptimal.totalExpectedPoints,
      );
      expect(isolatedOptimal.boostedDriverId, directOptimal.boostedDriverId);
      expect(isolatedOptimal.boostGain, directOptimal.boostGain);

      final directCenter = optimizer.buildDecisionCenter(
        currentDriverIds: _team.driverIds,
        currentConstructorIds: _team.constructorIds,
        currentBoostedDriverId: _team.boostedDriverId,
        driverPredictions: _drivers,
        constructorPredictions: _constructors,
        remainingBudgetMillions: _team.remainingBudgetMillions,
      );
      final isolatedCenter = await OptimizationIsolateRunner.decisionCenter(
        optimizer: optimizer,
        team: _team,
        drivers: _drivers,
        constructors: _constructors,
      );
      expect(
        isolatedCenter.currentTeam.boostedExpectedPoints,
        directCenter.currentTeam.boostedExpectedPoints,
      );
      expect(
        isolatedCenter.oneTransfer?.transfersIn,
        directCenter.oneTransfer?.transfersIn,
      );
      expect(
        isolatedCenter.twoTransfers?.transfersIn,
        directCenter.twoTransfers?.transfersIn,
      );
      expect(
        isolatedCenter.perfectTeam.driverIds,
        directCenter.perfectTeam.driverIds,
      );

      final directTransfers = optimizer.suggestTransfers(
        currentDriverIds: _team.driverIds,
        currentConstructorIds: _team.constructorIds,
        currentBoostedDriverId: _team.boostedDriverId,
        driverPredictions: _drivers,
        constructorPredictions: _constructors,
        remainingBudgetMillions: _team.remainingBudgetMillions,
      );
      final isolatedTransfers = await OptimizationIsolateRunner.transfers(
        optimizer: optimizer,
        team: _team,
        drivers: _drivers,
        constructors: _constructors,
      );
      expect(
        isolatedTransfers.map((plan) => plan.netExpectedGain),
        directTransfers.map((plan) => plan.netExpectedGain),
      );

      final round = RoundProjection(
        season: 2026,
        round: 7,
        raceName: 'Test GP',
        hasSprint: false,
        drivers: _drivers,
        constructors: _constructors,
      );
      const planner = StrategyPlanner();
      final directStrategy = planner.buildPlan(
        initialTeam: _team,
        projections: [round],
      );
      final isolatedStrategy = await OptimizationIsolateRunner.strategy(
        planner: planner,
        team: _team,
        projections: [round],
        history: const {},
      );
      expect(
        isolatedStrategy.totalExpectedPoints,
        directStrategy.totalExpectedPoints,
      );
      expect(
        isolatedStrategy.rounds.single.driverIds,
        directStrategy.rounds.single.driverIds,
      );

      const reviewEngine = DecisionReviewEngine();
      final directReview = reviewEngine.review(
        season: 2026,
        round: 7,
        raceName: 'Test GP',
        team: _team,
        actualDrivers: _drivers,
        actualConstructors: _constructors,
      );
      final isolatedReview = await OptimizationIsolateRunner.review(
        season: 2026,
        round: 7,
        raceName: 'Test GP',
        team: _team,
        drivers: _drivers,
        constructors: _constructors,
      );
      expect(isolatedReview.teamPoints, directReview.teamPoints);
      expect(isolatedReview.optimalPoints, directReview.optimalPoints);
      expect(isolatedReview.bestAssetId, directReview.bestAssetId);
    },
  );

  test('keeps the main isolate responsive during CPU work', () async {
    final messages = ReceivePort();
    addTearDown(messages.close);
    final started = Completer<int>();
    final subscription = messages.listen((message) {
      if (message is int && !started.isCompleted) started.complete(message);
    });
    addTearDown(subscription.cancel);

    final optimizer = _BusyOptimizer(messages.sendPort);
    var timerTicks = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 5), (_) {
      timerTicks++;
    });
    addTearDown(timer.cancel);

    final pending = OptimizationIsolateRunner.optimal(
      optimizer: optimizer,
      drivers: const [],
      constructors: const [],
      priority: TeamPriority.balanced,
    );
    final workerIdentity = await started.future;
    final result = await pending;

    expect(workerIdentity, isNot(Isolate.current.hashCode));
    expect(result.driverIds.single, startsWith('worker-$workerIdentity-'));
    expect(timerTicks, greaterThan(0));
  });

  test('continues the serial queue after an operation throws', () async {
    final messages = ReceivePort();
    addTearDown(messages.close);
    final events = <String>[];
    final badStarted = Completer<void>();
    final subscription = messages.listen((message) {
      final event = message as String;
      events.add(event);
      if (event == 'start:bad' && !badStarted.isCompleted) {
        badStarted.complete();
      }
    });
    addTearDown(subscription.cancel);

    final optimizer = _SequencedOptimizer(messages.sendPort);
    final failed = OptimizationIsolateRunner.optimal(
      optimizer: optimizer,
      drivers: [_prediction('bad', 1, 1)],
      constructors: const [],
      priority: TeamPriority.balanced,
    );
    await badStarted.future;
    final following = OptimizationIsolateRunner.optimal(
      optimizer: optimizer,
      drivers: [_prediction('good', 1, 1)],
      constructors: const [],
      priority: TeamPriority.balanced,
    );

    await expectLater(failed, throwsA(isA<StateError>()));
    final result = await following;
    // Let the final SendPort message be delivered before inspecting ordering.
    await Future<void>.delayed(Duration.zero);
    expect(result.driverIds, ['good']);
    expect(events, ['start:bad', 'end:bad', 'start:good', 'end:good']);
  });
}

class _BusyOptimizer extends TeamOptimizer {
  const _BusyOptimizer(this.sendPort);

  final SendPort sendPort;

  @override
  TeamCombo findOptimalTeam({
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double totalBudgetMillions,
    TeamPriority priority = TeamPriority.balanced,
  }) {
    final identity = Isolate.current.hashCode;
    sendPort.send(identity);
    final until = DateTime.now().add(const Duration(milliseconds: 150));
    var work = 0;
    while (DateTime.now().isBefore(until)) {
      work = (work * 31 + 1) & 0x7fffffff;
    }
    return TeamCombo(
      driverIds: ['worker-$identity-$work'],
      constructorIds: const [],
      totalCostMillions: 0,
      totalExpectedPoints: 0,
    );
  }
}

class _SequencedOptimizer extends TeamOptimizer {
  const _SequencedOptimizer(this.sendPort);

  final SendPort sendPort;

  @override
  TeamCombo findOptimalTeam({
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double totalBudgetMillions,
    TeamPriority priority = TeamPriority.balanced,
  }) {
    final id = driverPredictions.single.assetId;
    sendPort.send('start:$id');
    final until = DateTime.now().add(const Duration(milliseconds: 80));
    var work = 0;
    while (DateTime.now().isBefore(until)) {
      work = (work * 31 + 1) & 0x7fffffff;
    }
    sendPort.send('end:$id');
    if (id == 'bad') throw StateError('expected test failure');
    return TeamCombo(
      driverIds: [id],
      constructorIds: const [],
      totalCostMillions: 0,
      totalExpectedPoints: work.toDouble(),
    );
  }
}
