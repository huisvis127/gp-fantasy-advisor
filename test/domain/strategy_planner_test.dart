import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/strategy_planner.dart';
import 'package:gp_fantasy_advisor/domain/engine/team_optimizer.dart';
import 'package:gp_fantasy_advisor/domain/models/my_team.dart';
import 'package:gp_fantasy_advisor/domain/models/prediction.dart';
import 'package:gp_fantasy_advisor/domain/models/strategy_plan.dart';

AssetPrediction _prediction(
  String id,
  double points,
  double price, {
  double dnfRisk = 10,
}) => AssetPrediction(
  assetId: id,
  expectedPoints: points,
  winProbability: 0.05,
  podiumProbability: 0.15,
  top10Probability: 0.7,
  priceMillions: price,
  breakdown: {'riesgo_dnf': dnfRisk},
);

RoundProjection _round(int round, {bool sprint = false}) => RoundProjection(
  season: 2026,
  round: round,
  raceName: 'GP $round',
  hasSprint: sprint,
  drivers: [
    _prediction('d1', 30 + round.toDouble(), 12),
    _prediction('d2', 25, 11),
    _prediction('d3', 22, 10),
    _prediction('d4', 18, 9),
    _prediction('d5', 15, 8),
    _prediction('d6', 28, 10),
    _prediction('d7', 20, 7),
  ],
  constructors: [
    _prediction('c1', 40, 20),
    _prediction('c2', 35, 18),
    _prediction('c3', 30, 15),
  ],
);

void main() {
  const planner = StrategyPlanner();
  const team = MyTeam(
    driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
    constructorIds: ['c1', 'c2'],
    remainingBudgetMillions: 0,
  );

  test('encadena tres carreras con boost, cambios y valor proyectado', () {
    final plan = planner.buildPlan(
      initialTeam: team,
      projections: [_round(1), _round(2, sprint: true), _round(3)],
      officialPointHistory: {
        for (final id in ['d1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7'])
          id: [20, 18],
      },
    );

    expect(plan.rounds, hasLength(3));
    expect(plan.totalExpectedPoints, greaterThan(0));
    expect(plan.rounds.every((round) => round.driverIds.length == 5), isTrue);
    expect(
      plan.rounds.every((round) => round.constructorIds.length == 2),
      isTrue,
    );
    expect(
      plan.rounds.every((round) => round.boostedDriverId.isNotEmpty),
      isTrue,
    );
  });

  test('genera recomendaciones para todos los chips disponibles', () {
    final plan = planner.buildPlan(
      initialTeam: team,
      projections: [_round(1, sprint: true)],
    );
    final advice = planner.adviseChips(team: team, plan: plan);

    expect(advice.map((item) => item.chip), contains('Wildcard'));
    expect(advice.map((item) => item.chip), contains('Triple Boost'));
    expect(advice, hasLength(6));
    expect(advice.first.score, greaterThanOrEqualTo(advice.last.score));
  });

  test('elige la mejor ruta global aunque no sea la mejor del primer GP', () {
    const globalPlanner = StrategyPlanner(optimizer: _BranchingOptimizer());
    final first = _roundWithAlternatives(1, d6Points: 40, d7Points: 35);
    final second = _roundWithAlternatives(2, d6Points: 0, d7Points: 100);
    final third = _roundWithAlternatives(3, d6Points: 0, d7Points: 100);

    final plan = globalPlanner.buildPlan(
      initialTeam: team,
      projections: [first, second, third],
    );

    // d6 gana el GP 1 de forma aislada (40 vs 35), pero d7 domina el
    // horizonte completo. Esta es la diferencia frente al antiguo greedy.
    expect(plan.rounds, hasLength(3));
    expect(plan.rounds.first.driverIds, contains('d7'));
    expect(plan.rounds.first.driverIds, isNot(contains('d6')));
  });
}

RoundProjection _roundWithAlternatives(
  int round, {
  required double d6Points,
  required double d7Points,
}) => RoundProjection(
  season: 2026,
  round: round,
  raceName: 'GP $round',
  hasSprint: false,
  drivers: [
    _prediction('d1', 10, 10),
    _prediction('d2', 10, 10),
    _prediction('d3', 10, 10),
    _prediction('d4', 10, 10),
    _prediction('d5', 10, 10),
    _prediction('d6', d6Points, 10),
    _prediction('d7', d7Points, 10),
  ],
  constructors: [_prediction('c1', 10, 10), _prediction('c2', 10, 10)],
);

class _BranchingOptimizer extends TeamOptimizer {
  const _BranchingOptimizer();

  @override
  List<TransferPlan> transferCandidates({
    required List<String> currentDriverIds,
    required List<String> currentConstructorIds,
    required List<AssetPrediction> driverPredictions,
    required List<AssetPrediction> constructorPredictions,
    required double remainingBudgetMillions,
    int maxTransfersToConsider = 3,
    int extraTransferPenalty = -10,
    int candidatesPerTransferCount = 2,
  }) {
    final byId = {
      for (final prediction in [
        ...driverPredictions,
        ...constructorPredictions,
      ])
        prediction.assetId: prediction,
    };
    TeamCombo combo(List<String> drivers) => TeamCombo(
      driverIds: drivers,
      constructorIds: currentConstructorIds,
      totalCostMillions: [
        ...drivers,
        ...currentConstructorIds,
      ].fold(0, (sum, id) => sum + byId[id]!.priceMillions),
      totalExpectedPoints: [
        ...drivers,
        ...currentConstructorIds,
      ].fold(0, (sum, id) => sum + byId[id]!.expectedPoints),
    );

    TransferPlan keep(List<String> drivers) => TransferPlan(
      transfersOut: const [],
      transfersIn: const [],
      numberOfTransfers: 0,
      extraTransferPenaltyApplied: 0,
      resultingTeam: combo(drivers),
      netExpectedGain: 0,
    );
    if (!currentDriverIds.contains('d5')) return [keep(currentDriverIds)];

    TransferPlan swapTo(String id) {
      final drivers = [...currentDriverIds];
      drivers[drivers.indexOf('d5')] = id;
      return TransferPlan(
        transfersOut: const ['d5'],
        transfersIn: [id],
        numberOfTransfers: 1,
        extraTransferPenaltyApplied: 0,
        resultingTeam: combo(drivers),
        netExpectedGain: byId[id]!.expectedPoints - byId['d5']!.expectedPoints,
      );
    }

    return [keep(currentDriverIds), swapTo('d6'), swapTo('d7')];
  }
}
