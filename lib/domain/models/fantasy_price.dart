enum FantasyAssetType { driver, constructor }

class FantasyPrice {
  const FantasyPrice({
    required this.assetId,
    required this.assetType,
    required this.season,
    required this.round,
    required this.priceMillions,
  });

  final String assetId;
  final FantasyAssetType assetType;
  final int season;
  final int round;
  final double priceMillions;
}
