import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/decision_review_engine.dart';
import 'package:gp_fantasy_advisor/domain/models/my_team.dart';
import 'package:gp_fantasy_advisor/domain/models/prediction.dart';

AssetPrediction _actual(String id, double points, double price) =>
    AssetPrediction(
      assetId: id,
      expectedPoints: points,
      winProbability: 0,
      podiumProbability: 0,
      top10Probability: 0,
      priceMillions: price,
      breakdown: const {},
    );

void main() {
  test('compara el equipo guardado con el óptimo usando puntos reales', () {
    final drivers = [
      _actual('d1', 30, 10),
      _actual('d2', 25, 10),
      _actual('d3', 20, 10),
      _actual('d4', 15, 10),
      _actual('d5', 5, 10),
      _actual('d6', 40, 10),
    ];
    final constructors = [
      _actual('c1', 31, 20),
      _actual('c2', 20, 20),
      _actual('c3', 35, 20),
    ];
    const team = MyTeam(
      driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
      constructorIds: ['c1', 'c2'],
      remainingBudgetMillions: 10,
      boostedDriverId: 'd2',
    );

    final review = const DecisionReviewEngine().review(
      season: 2026,
      round: 1,
      raceName: 'Australia',
      team: team,
      actualDrivers: drivers,
      actualConstructors: constructors,
    );

    expect(review.teamPoints, 171);
    expect(review.optimalPoints, greaterThan(review.teamPoints));
    expect(review.missedPoints, greaterThan(0));
    expect(review.bestAssetId, 'c1');
    expect(review.worstAssetId, 'd5');
  });
}
