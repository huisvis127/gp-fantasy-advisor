import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/services/fantasy_chip_parser.dart';

void main() {
  test('lee las banderas y rondas con los nombres heredados de F1 Fantasy', () {
    final usage = parseFantasyChipUsage({
      'Data': {
        'Value': {
          'isWildcardTaken': 1,
          'wildCardTakenGD': 4,
          'isExtraDRSTaken': 1,
          'extraDrsTakenGD': 7,
          'isNoNigativeTaken': 0,
        },
      },
    });

    expect(usage['wildcard'], 4);
    expect(usage['triple_boost'], 7);
    expect(usage, isNot(contains('no_negative')));
  });

  test('lee la lista normalizada de chips de los equipos de liga', () {
    final usage = parseFantasyChipUsage({
      'chipsUsed': [
        {'name': 'limitless', 'round': 3},
        {'name': 'auto_pilot', 'round': 9},
      ],
    });

    expect(usage, {'limitless': 3, 'autopilot': 9});
  });
}
