import 'dart:math' as math;

import '../models/prediction.dart';
import '../models/price_forecast.dart';

/// Reglas de variación de precio 2026 basadas en la media móvil de PPM de
/// tres jornadas. El histórico oficial aporta las dos primeras y el motor
/// de predicción aporta la tercera.
class PriceForecastEngine {
  const PriceForecastEngine();

  static const double poorBoundary = 0.6;
  static const double goodBoundary = 0.9;
  static const double greatBoundary = 1.2;
  static const double premiumBoundaryMillions = 18.5;

  PriceForecast forecast({
    required AssetPrediction prediction,
    required List<int> previousPoints,
  }) {
    final hasOfficialHistory = previousPoints.length >= 2;
    final history = hasOfficialHistory
        ? previousPoints.take(2).toList()
        : <int>[
            ...previousPoints,
            ...List<int>.filled(
              2 - previousPoints.length,
              prediction.expectedPoints.round(),
            ),
          ];
    final projectedPpm = _averagePpm(
      price: prediction.priceMillions,
      points: [...history, prediction.expectedPoints],
    );
    final projectedBand = bandForPpm(projectedPpm);
    const minimumStandardDeviation = 8.0;
    final standardDeviation = math.max(
      minimumStandardDeviation,
      prediction.expectedPoints.abs() * 0.35 +
          (1 - prediction.top10Probability) * 8,
    );
    final thresholds = <double>[
      requiredPoints(
        boundary: poorBoundary,
        price: prediction.priceMillions,
        previousPoints: history,
      ),
      requiredPoints(
        boundary: goodBoundary,
        price: prediction.priceMillions,
        previousPoints: history,
      ),
      requiredPoints(
        boundary: greatBoundary,
        price: prediction.priceMillions,
        previousPoints: history,
      ),
    ];
    final cdf = thresholds
        .map(
          (threshold) => _normalCdf(
            threshold,
            prediction.expectedPoints,
            standardDeviation,
          ),
        )
        .toList();
    final probabilities = <double>[
      cdf[0],
      (cdf[1] - cdf[0]).clamp(0, 1).toDouble(),
      (cdf[2] - cdf[1]).clamp(0, 1).toDouble(),
      (1 - cdf[2]).clamp(0, 1).toDouble(),
    ];
    const bands = PricePerformanceBand.values;
    final bandProbabilities = <PriceBandProbability>[
      for (var i = 0; i < bands.length; i++)
        PriceBandProbability(
          band: bands[i],
          probability: probabilities[i],
          priceDeltaMillions: deltaForBand(bands[i], prediction.priceMillions),
        ),
    ];

    return PriceForecast(
      assetId: prediction.assetId,
      currentPriceMillions: prediction.priceMillions,
      expectedPoints: prediction.expectedPoints,
      previousPoints: List.unmodifiable(history),
      projectedAveragePpm: projectedPpm,
      projectedDeltaMillions: deltaForBand(
        projectedBand,
        prediction.priceMillions,
      ),
      requiredForGood: thresholds[1].ceil(),
      requiredForGreat: thresholds[2].ceil(),
      bandProbabilities: List.unmodifiable(bandProbabilities),
      hasOfficialHistory: hasOfficialHistory,
    );
  }

  double requiredPoints({
    required double boundary,
    required double price,
    required List<int> previousPoints,
  }) {
    final known = previousPoints.take(2).fold<int>(0, (sum, p) => sum + p);
    return boundary * 3 * price - known;
  }

  PricePerformanceBand bandForPpm(double ppm) {
    if (ppm < poorBoundary) return PricePerformanceBand.terrible;
    if (ppm < goodBoundary) return PricePerformanceBand.poor;
    if (ppm <= greatBoundary) return PricePerformanceBand.good;
    return PricePerformanceBand.great;
  }

  double deltaForBand(PricePerformanceBand band, double price) {
    final premium = price >= premiumBoundaryMillions;
    return switch (band) {
      PricePerformanceBand.terrible => premium ? -0.3 : -0.6,
      PricePerformanceBand.poor => premium ? -0.1 : -0.2,
      PricePerformanceBand.good => premium ? 0.1 : 0.2,
      PricePerformanceBand.great => premium ? 0.3 : 0.6,
    };
  }

  double _averagePpm({required double price, required List<num> points}) {
    if (price <= 0 || points.isEmpty) return 0;
    return points.fold<double>(0, (sum, value) => sum + value) /
        points.length /
        price;
  }

  /// Aproximación logística suave de la CDF normal, suficiente para expresar
  /// incertidumbre sin introducir una dependencia matemática adicional.
  double _normalCdf(double x, double mean, double standardDeviation) {
    if (standardDeviation <= 0) return x < mean ? 0 : 1;
    final z = (x - mean) / standardDeviation;
    return 1 / (1 + math.exp(-1.702 * z));
  }
}
