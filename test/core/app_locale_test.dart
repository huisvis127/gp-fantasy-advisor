import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/app_locale.dart';

void main() {
  test('todo el espacio Fantasy existe en los cinco idiomas', () {
    const keys = [
      'ideal_team',
      'market_prices',
      'live_now',
      'season_planner',
      'one_change',
      'two_changes',
      'perfect_team',
      'out',
      'in',
      'cost',
      'bank',
      'impact',
      'chip_advisor',
      'decision_review',
    ];

    for (final language in supportedLanguageCodes) {
      final strings = AppStrings(language);
      for (final key in keys) {
        expect(strings.t(key), isNot(key), reason: '$language: $key');
      }
    }
  });
}
