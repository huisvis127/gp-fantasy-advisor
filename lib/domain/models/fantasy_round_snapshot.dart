import 'fantasy_points.dart';
import 'fantasy_price.dart';

/// Foto pública de una jornada oficial de F1 Fantasy.
class FantasyRoundSnapshot {
  const FantasyRoundSnapshot({
    required this.season,
    required this.round,
    required this.prices,
    required this.points,
    this.isCurrent = false,
  });

  final int season;
  final int round;
  final List<FantasyPrice> prices;
  final List<FantasyPoints> points;
  final bool isCurrent;
}
