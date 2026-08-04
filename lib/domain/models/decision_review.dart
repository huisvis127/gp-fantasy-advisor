class DecisionReview {
  const DecisionReview({
    required this.season,
    required this.round,
    required this.raceName,
    required this.teamPoints,
    required this.optimalPoints,
    required this.missedPoints,
    required this.boostImpact,
    required this.bestAssetId,
    required this.bestAssetPoints,
    required this.worstAssetId,
    required this.worstAssetPoints,
  });

  final int season;
  final int round;
  final String raceName;
  final double teamPoints;
  final double optimalPoints;
  final double missedPoints;
  final double boostImpact;
  final String bestAssetId;
  final double bestAssetPoints;
  final String worstAssetId;
  final double worstAssetPoints;
}
