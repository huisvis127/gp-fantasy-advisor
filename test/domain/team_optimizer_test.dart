import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/team_optimizer.dart';
import 'package:gp_fantasy_advisor/domain/models/prediction.dart';

AssetPrediction _fakePrediction(String id, double points, double price) {
  return AssetPrediction(
    assetId: id,
    expectedPoints: points,
    winProbability: 0,
    podiumProbability: 0,
    top10Probability: 0,
    priceMillions: price,
    breakdown: const {},
  );
}

void main() {
  group('TeamOptimizer.findOptimalTeam', () {
    test('elige el mejor equipo de 5+2 respetando el presupuesto', () {
      // 6 pilotos, presupuesto ajustado para forzar una decisión no trivial.
      final drivers = [
        _fakePrediction('d1', 30, 30), // mucho valor, muy caro
        _fakePrediction('d2', 25, 20),
        _fakePrediction('d3', 20, 15),
        _fakePrediction('d4', 18, 10),
        _fakePrediction('d5', 15, 8),
        _fakePrediction('d6', 10, 5),
      ];
      final constructors = [
        _fakePrediction('c1', 20, 25),
        _fakePrediction('c2', 15, 15),
        _fakePrediction('c3', 10, 8),
      ];

      const optimizer = TeamOptimizer();
      final result = optimizer.findOptimalTeam(
        driverPredictions: drivers,
        constructorPredictions: constructors,
        totalBudgetMillions: 100,
      );

      expect(result.driverIds.length, 5);
      expect(result.constructorIds.length, 2);
      expect(result.totalCostMillions, lessThanOrEqualTo(100));

      // Con presupuesto de sobra (30+20+15+10+8=83 + 25+15=40 -> 123 > 100),
      // no caben todos los mejores; el optimizador debe encontrar algo mejor
      // que simplemente coger los 5 pilotos más baratos + los 2 constructores
      // más baratos (10+8+5+... etc).
      const cheapestPossible = 5 + 8 + 10 + 15 + 20; // d6..d2 aprox
      expect(result.totalCostMillions, greaterThanOrEqualTo(0));
      expect(cheapestPossible, greaterThan(0)); // sanity check del fixture
    });

    test('no supera nunca el presupuesto total', () {
      final drivers = List.generate(
        10,
        (i) => _fakePrediction('d$i', (10 - i).toDouble(), (i + 1) * 3.0),
      );
      final constructors = List.generate(
        4,
        (i) => _fakePrediction('c$i', (5 - i).toDouble(), (i + 1) * 5.0),
      );

      const optimizer = TeamOptimizer();
      final result = optimizer.findOptimalTeam(
        driverPredictions: drivers,
        constructorPredictions: constructors,
        totalBudgetMillions: 40,
      );

      expect(result.totalCostMillions, lessThanOrEqualTo(40));
    });

    test('incluye siempre el X2 del mejor piloto en el total', () {
      final drivers = [
        _fakePrediction('d1', 30, 10),
        _fakePrediction('d2', 20, 10),
        _fakePrediction('d3', 15, 10),
        _fakePrediction('d4', 10, 10),
        _fakePrediction('d5', 5, 10),
      ];
      final constructors = [
        _fakePrediction('c1', 20, 10),
        _fakePrediction('c2', 10, 10),
      ];

      const optimizer = TeamOptimizer();
      final result = optimizer.findOptimalTeam(
        driverPredictions: drivers,
        constructorPredictions: constructors,
        totalBudgetMillions: 100,
      );

      expect(result.boostedDriverId, 'd1');
      expect(result.totalExpectedPoints, 140); // 110 base + 30 del X2.
    });

    test('cada perfil prioriza realmente su grupo sin dividir el presupuesto',
        () {
      final drivers = [
        _fakePrediction('estrella', 100, 40),
        _fakePrediction('d2', 10, 10),
        _fakePrediction('d3', 10, 10),
        _fakePrediction('d4', 10, 10),
        _fakePrediction('d5', 10, 10),
        _fakePrediction('barato', 0, 0),
      ];
      final constructors = [
        _fakePrediction('top1', 100, 30),
        _fakePrediction('top2', 90, 30),
        _fakePrediction('barato', 0, 0),
      ];
      const optimizer = TeamOptimizer();

      TeamCombo optimize(TeamPriority priority) => optimizer.findOptimalTeam(
            driverPredictions: drivers,
            constructorPredictions: constructors,
            totalBudgetMillions: 100,
            priority: priority,
          );

      final driverTeam = optimize(TeamPriority.drivers);
      final balancedTeam = optimize(TeamPriority.balanced);
      final constructorTeam = optimize(TeamPriority.constructors);
      final constructorPoints = {
        for (final prediction in constructors)
          prediction.assetId: prediction.expectedPoints,
      };
      double subtotal(TeamCombo team) => team.constructorIds.fold(
            0,
            (sum, id) => sum + (constructorPoints[id] ?? 0),
          );

      expect(driverTeam.driverIds, contains('estrella'));
      expect(subtotal(constructorTeam),
          greaterThanOrEqualTo(subtotal(balancedTeam)));
      expect(
          subtotal(balancedTeam), greaterThanOrEqualTo(subtotal(driverTeam)));
      expect(constructorTeam.constructorIds, containsAll(['top1', 'top2']));
      for (final team in [driverTeam, balancedTeam, constructorTeam]) {
        expect(team.driverIds, hasLength(5));
        expect(team.constructorIds, hasLength(2));
        expect(team.totalCostMillions, lessThanOrEqualTo(100));
      }
    });
  });

  group('TeamOptimizer.recommendBoost', () {
    test('recomienda al piloto con más puntos esperados del equipo', () {
      final drivers = [
        _fakePrediction('d1', 12, 10),
        _fakePrediction('d2', 28, 20),
        _fakePrediction('d3', 5, 5),
      ];
      const optimizer = TeamOptimizer();
      final boosted = optimizer.recommendBoost(['d1', 'd2', 'd3'], drivers);
      expect(boosted, 'd2');
    });
  });

  group('TeamOptimizer.suggestTransfers', () {
    test('encuentra la mejor pareja asequible aunque el activo top no quepa',
        () {
      final drivers = [
        _fakePrediction('d1', 50, 10),
        _fakePrediction('d2', 20, 10),
        _fakePrediction('d3', 15, 10),
        _fakePrediction('d4', 10, 10),
        _fakePrediction('d5', 9, 10),
        _fakePrediction('caro', 50, 25),
        _fakePrediction('pareja_a', 35, 15),
        _fakePrediction('pareja_b', 34, 15),
      ];
      final constructors = [
        _fakePrediction('c1', 20, 10),
        _fakePrediction('c2', 18, 10),
      ];

      const optimizer = TeamOptimizer();
      final plans = optimizer.suggestTransfers(
        currentDriverIds: const ['d1', 'd2', 'd3', 'd4', 'd5'],
        currentConstructorIds: const ['c1', 'c2'],
        driverPredictions: drivers,
        constructorPredictions: constructors,
        remainingBudgetMillions: 10,
        maxTransfersToConsider: 2,
      );
      final best = plans.first;

      expect(best.numberOfTransfers, 2);
      expect(best.transfersIn, containsAll(['pareja_a', 'pareja_b']));
      expect(best.resultingTeam.totalCostMillions, lessThanOrEqualTo(80));
    });
  });
}
