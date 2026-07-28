import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/team_colors.dart';

void main() {
  test('nombres humanos e ids usan el mismo color de escuderia', () {
    expect(teamColor('Red Bull Racing'), teamColor('red_bull'));
    expect(teamColor('Alpine F1 Team'), teamColor('alpine'));
    expect(teamColor('RB F1 Team'), teamColor('rb'));
    expect(teamColor('Haas F1 Team'), teamColor('haas'));
    expect(teamColor('Cadillac F1 Team'), teamColor('cadillac'));
  });
}
