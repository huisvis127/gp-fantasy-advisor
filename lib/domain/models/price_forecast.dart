enum PricePerformanceBand { terrible, poor, good, great }

class PriceBandProbability {
  const PriceBandProbability({
    required this.band,
    required this.probability,
    required this.priceDeltaMillions,
  });

  final PricePerformanceBand band;
  final double probability;
  final double priceDeltaMillions;
}

class PriceForecast {
  const PriceForecast({
    required this.assetId,
    required this.currentPriceMillions,
    required this.expectedPoints,
    required this.previousPoints,
    required this.projectedAveragePpm,
    required this.projectedDeltaMillions,
    required this.requiredForGood,
    required this.requiredForGreat,
    required this.bandProbabilities,
    required this.hasOfficialHistory,
  });

  final String assetId;
  final double currentPriceMillions;
  final double expectedPoints;
  final List<int> previousPoints;
  final double projectedAveragePpm;
  final double projectedDeltaMillions;
  final int requiredForGood;
  final int requiredForGreat;
  final List<PriceBandProbability> bandProbabilities;
  final bool hasOfficialHistory;

  double get riseProbability => bandProbabilities
      .where(
        (item) =>
            item.band == PricePerformanceBand.good ||
            item.band == PricePerformanceBand.great,
      )
      .fold(0.0, (sum, item) => sum + item.probability);
}
