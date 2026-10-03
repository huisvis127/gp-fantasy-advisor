import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/price_forecast_engine.dart';
import 'package:gp_fantasy_advisor/domain/models/prediction.dart';
import 'package:gp_fantasy_advisor/domain/models/price_forecast.dart';

AssetPrediction _prediction({double points = 20, double price = 10}) =>
    AssetPrediction(
      assetId: 'test',
      expectedPoints: points,
      winProbability: 0.05,
      podiumProbability: 0.15,
      top10Probability: 0.7,
      priceMillions: price,
      breakdown: const {},
    );

void main() {
  const engine = PriceForecastEngine();

  test('calcula los puntos necesarios con la ventana de tres carreras', () {
    final required = engine.requiredPoints(
      boundary: PriceForecastEngine.goodBoundary,
      price: 10,
      previousPoints: const [8, 9],
    );

    expect(required, closeTo(10, 0.0001));
  });

  test('aplica los cuatro tramos de precio para activos baratos', () {
    expect(engine.deltaForBand(PricePerformanceBand.terrible, 10), -0.6);
    expect(engine.deltaForBand(PricePerformanceBand.poor, 10), -0.2);
    expect(engine.deltaForBand(PricePerformanceBand.good, 10), 0.2);
    expect(engine.deltaForBand(PricePerformanceBand.great, 10), 0.6);
  });

  test('aplica los cuatro tramos de precio para activos premium', () {
    expect(engine.deltaForBand(PricePerformanceBand.terrible, 18.5), -0.3);
    expect(engine.deltaForBand(PricePerformanceBand.poor, 18.5), -0.1);
    expect(engine.deltaForBand(PricePerformanceBand.good, 18.5), 0.1);
    expect(engine.deltaForBand(PricePerformanceBand.great, 18.5), 0.3);
  });

  test('genera probabilidades que suman uno e identifica subida', () {
    final result = engine.forecast(
      prediction: _prediction(points: 22, price: 10),
      previousPoints: const [14, 12],
    );

    final total = result.bandProbabilities.fold<double>(
      0,
      (sum, item) => sum + item.probability,
    );
    expect(total, closeTo(1, 0.0001));
    expect(result.projectedDeltaMillions, 0.6);
    expect(result.riseProbability, greaterThan(0.5));
    expect(result.hasOfficialHistory, isTrue);
  });

  test('marca el histórico incompleto como estimado', () {
    final result = engine.forecast(
      prediction: _prediction(),
      previousPoints: const [],
    );

    expect(result.hasOfficialHistory, isFalse);
    expect(result.previousPoints, hasLength(2));
  });
}
