import 'fantasy_price.dart';

class LiveSessionScore {
  const LiveSessionScore({required this.sessionName, required this.points});

  final String sessionName;
  final double? points;
}

class LiveAssetScore {
  const LiveAssetScore({
    required this.assetId,
    required this.assetType,
    required this.displayName,
    required this.points,
    required this.projectedPoints,
    required this.selectedPercentage,
    required this.captainSelectedPercentage,
    required this.sessions,
  });

  final String assetId;
  final FantasyAssetType assetType;
  final String displayName;
  final double points;
  final double projectedPoints;
  final double selectedPercentage;
  final double captainSelectedPercentage;
  final List<LiveSessionScore> sessions;
}

class LiveFantasySnapshot {
  const LiveFantasySnapshot({
    required this.season,
    required this.round,
    required this.meetingName,
    required this.sessionName,
    required this.isLive,
    required this.isLocked,
    required this.updatedAt,
    required this.assets,
    this.deadline,
  });

  final int season;
  final int round;
  final String meetingName;
  final String sessionName;
  final bool isLive;
  final bool isLocked;
  final DateTime updatedAt;
  final DateTime? deadline;
  final List<LiveAssetScore> assets;
}
