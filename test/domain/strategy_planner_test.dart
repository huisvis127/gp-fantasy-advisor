import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/strategy_planner.dart';
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
}
