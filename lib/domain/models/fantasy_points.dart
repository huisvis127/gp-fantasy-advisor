import 'fantasy_price.dart';

class FantasyPoints {
  const FantasyPoints({
    required this.assetId,
    required this.assetType,
    required this.season,
    required this.round,
    required this.points,
  });

  final String assetId;
  final FantasyAssetType assetType;
  final int season;
  final int round;
  final int points;
}
