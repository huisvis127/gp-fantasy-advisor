import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gp_fantasy_advisor/core/app_appearance.dart';
import 'package:gp_fantasy_advisor/core/theme.dart';
import 'package:gp_fantasy_advisor/ui/widgets/ref_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    AppColors.brightness = Brightness.dark;
  });
  tearDown(() => AppColors.brightness = Brightness.dark);

  test('recupera el modo claro guardado', () async {
    SharedPreferences.setMockInitialValues({'light_mode': true});
    final controller = AppAppearanceController();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, Brightness.light);
    controller.dispose();
  });

  test('guarda ambos modos y prioriza una elección durante la carga', () async {
    SharedPreferences.setMockInitialValues({'light_mode': true});
    final controller = AppAppearanceController();
    await controller.setLightMode(false);
    expect(controller.state, Brightness.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('light_mode'), false);
    await controller.setLightMode(true);
    expect(controller.state, Brightness.light);
    expect(prefs.getBool('light_mode'), true);
    controller.dispose();
  });

  test('los textos del modo claro tienen contraste legible', () {
    AppColors.brightness = Brightness.light;
    final background = AppColors.surface1.computeLuminance();
    for (final foreground in [
      AppColors.textPrimary,
      AppColors.textSecondary,
      AppColors.textTertiary,
      AppColors.cyan,
      AppColors.ok,
    ]) {
      expect(
        (background + .05) / (foreground.computeLuminance() + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets('una tarjeta constante se actualiza al cambiar de tema', (
    tester,
  ) async {
    const card = RefCard(child: Kicker('Mi liga'));
    Future<void> render(Brightness brightness) async {
      AppColors.brightness = brightness;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          themeAnimationDuration: Duration.zero,
          home: const Scaffold(body: card),
        ),
      );
      await tester.pump();
    }

    await render(Brightness.dark);
    final dark = tester.widget<Text>(find.text('MI LIGA')).style!.color;
    await render(Brightness.light);
    expect(
      tester.widget<Text>(find.text('MI LIGA')).style!.color,
      AppColors.lime,
    );
    expect(tester.widget<Text>(find.text('MI LIGA')).style!.color, isNot(dark));
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byWidget(card),
        matching: find.byType(Container),
      ),
    );
    expect((container.decoration! as BoxDecoration).gradient!.colors, [
      AppColors.surface2,
      AppColors.surface1,
    ]);
    expect(tester.takeException(), isNull);
  });
}
