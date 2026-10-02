import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/core/league_colors.dart';
import 'package:gp_fantasy_advisor/core/league_colors_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'todas las vistas comparten el cambio y se conserva al volver a abrir',
    () async {
      final container = ProviderContainer();
      final viewA = <Map<String, int>>[];
      final viewB = <Map<String, int>>[];
      container.listen(
        leagueTeamColorsProvider('a'),
        (_, next) => viewA.add(next),
      );
      container.listen(
        leagueTeamColorsProvider('a'),
        (_, next) => viewB.add(next),
      );
      final controller = container.read(leagueTeamColorsProvider('a').notifier);
      await Future.wait([
        controller.select('driver:1', 29),
        controller.select('driver:2', 8),
      ]);
      expect(viewA.last, {'driver:1': 29, 'driver:2': 8});
      expect(viewB.last, viewA.last);
      expect(await LeagueColors.load('a'), viewA.last);
      expect(await LeagueColors.load('b'), isEmpty);
      container.dispose();
      final reopened = ProviderContainer();
      reopened.read(leagueTeamColorsProvider('a'));
      await Future<void>.delayed(Duration.zero);
      expect(reopened.read(leagueTeamColorsProvider('a')), {
        'driver:1': 29,
        'driver:2': 8,
      });
      reopened.dispose();
    },
  );

  test('neones y normales son legibles en ambos temas conservando el tono', () {
    for (final brightness in Brightness.values) {
      final background = brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF101015);
      for (final choice in LeagueColors.palette) {
        final color = LeagueColors.textColor(choice.color, brightness);
        final a = color.computeLuminance();
        final b = background.computeLuminance();
        final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });
}
