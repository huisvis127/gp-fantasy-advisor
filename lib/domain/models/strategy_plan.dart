import 'prediction.dart';

class RoundProjection {
  const RoundProjection({
    required this.season,
    required this.round,
    required this.raceName,
    required this.hasSprint,
    required this.drivers,
    required this.constructors,
  });

  final int season;
  final int round;
  final String raceName;
  final bool hasSprint;
  final List<AssetPrediction> drivers;
  final List<AssetPrediction> constructors;
}

class PlannedRound {
  const PlannedRound({
    required this.projection,
    required this.driverIds,
    required this.constructorIds,
    required this.transfersOut,
    required this.transfersIn,
    required this.transferPenalty,
    required this.boostedDriverId,
    required this.expectedPoints,
    required this.projectedTeamValueMillions,
    required this.projectedPriceGainMillions,
  });

  final RoundProjection projection;
  final List<String> driverIds;
  final List<String> constructorIds;
  final List<String> transfersOut;
  final List<String> transfersIn;
  final int transferPenalty;
  final String boostedDriverId;
  final double expectedPoints;
  final double projectedTeamValueMillions;
  final double projectedPriceGainMillions;
}

class MultiRoundPlan {
  const MultiRoundPlan({
    required this.rounds,
    required this.totalExpectedPoints,
    required this.totalProjectedPriceGainMillions,
  });

  final List<PlannedRound> rounds;
  final double totalExpectedPoints;
  final double totalProjectedPriceGainMillions;
}

enum ChipRecommendationLevel { hold, consider, use }

class ChipAdvice {
  const ChipAdvice({
    required this.chip,
    required this.level,
    required this.score,
    required this.reason,
  });

  final String chip;
  final ChipRecommendationLevel level;
  final int score;
  final String reason;
}
