import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/models/my_team.dart';

void main() {
  const team = MyTeam(
    driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
    constructorIds: ['c1', 'c2'],
    remainingBudgetMillions: 0,
    boostedDriverId: 'd2',
  );
  const points = {
    'd1': 10.0,
    'd2': 20.0,
    'd3': 5.0,
    'd4': 5.0,
    'd5': 5.0,
    'c1': 25.0,
    'c2': 20.0,
  };

  test(
    'la proyección suma los siete activos y duplica el capitán importado',
    () {
      expect(team.projectedPoints(points), 110);
    },
  );

  test('si falta capitán usa solo la sugerencia válida del usuario', () {
    const withoutCaptain = MyTeam(
      driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
      constructorIds: ['c1', 'c2'],
      remainingBudgetMillions: 0,
    );
    expect(
      withoutCaptain.projectedPoints(points, suggestedBoostedDriverId: 'd1'),
      100,
    );
    expect(
      withoutCaptain.projectedPoints(points, suggestedBoostedDriverId: 'c1'),
      90,
    );
    expect(withoutCaptain.projectedPoints(points), 90);
  });

  test('el boost duplica también un resultado negativo', () {
    const negativeCaptain = MyTeam(
      driverIds: ['d1', 'd2', 'd3', 'd4', 'd5'],
      constructorIds: ['c1', 'c2'],
      remainingBudgetMillions: 0,
      boostedDriverId: 'd2',
    );
    expect(negativeCaptain.projectedPoints({...points, 'd2': -10}), 50);
  });
}
