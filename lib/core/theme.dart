import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño extraído 1:1 del index.html de la app de referencia
/// ("Fantasy Advisor" MotoGP, PLAN_DESARROLLO.md sección 1.1 y 6).
///
/// Tokens CSS de la referencia:
///   --bg:#08080b  --bg-2:#0b0b10
///   --surface-1:#101015 --surface-2:#16161d --surface-3:#1e1e25 --surface-4:#262631
///   --t1:#f9f9fb --t2:#a0a0b0 --t3:#606070
///   --b1:rgba(255,255,255,.08) --b2:rgba(255,255,255,.14)
/// La estructura visual conserva la referencia de MotoGP, pero la identidad
/// de esta app usa rojo racing como acento principal.
///   --ok:#00e096 --warn:#ffb833 --err:#ff4466
///   Radios: 7 / 10 / 14 / 20 / 26 px
///   Fuentes: Syne 800 (títulos), DM Sans (cuerpo), JetBrains Mono (etiquetas).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF08080B); // --bg
  static const Color background2 = Color(0xFF0B0B10); // --bg-2
  static const Color surface1 = Color(0xFF101015);
  static const Color surface2 = Color(0xFF16161D);
  static const Color surface3 = Color(0xFF1E1E25);
  static const Color surface4 = Color(0xFF262631);

  static const Color textPrimary = Color(0xFFF9F9FB); // --t1
  static const Color textSecondary = Color(0xFFA0A0B0); // --t2
  static const Color textTertiary = Color(0xFF606070); // --t3

  static const Color border1 = Color(0x14FFFFFF); // rgba(255,255,255,.08)
  static const Color border2 = Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static const Color glassFill = Color(0x0AFFFFFF); // --glass .04
  static const Color glassStrong = Color(0x12FFFFFF); // --glass-strong .07

  // Se conservan los nombres internos `lime`/`lime2` para no romper widgets
  // existentes; visualmente son ahora el rojo principal de la app F1.
  static const Color lime = Color(0xFFFF1838);
  static const Color lime2 = Color(0xFFFF5268);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color magenta = Color(0xFFFF3CB8);
  static const Color violet = Color(0xFF9B5CFF);
  static const Color orange = Color(0xFFFF7000);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC7C9D6);

  static const Color ok = Color(0xFF00E096);
  static const Color warning = Color(0xFFFFB833);
  static const Color error = Color(0xFFFF4466);

  // Alias usados por widgets antiguos (compatibilidad).
  static const Color glassBorder = border1;
  static const Color accentCyan = cyan;
  static const Color accentLime = lime;
  static const Color accentMagenta = magenta;
  static const Color accentViolet = violet;
  static const Color accentOrange = orange;
  static const Color backgroundDeep = background;
}

class AppRadii {
  AppRadii._();

  static const double xs = 7;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 26;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Tipografías de la referencia. `google_fonts` descarga y cachea la fuente
/// la primera vez que hay red; si no hay red usa la fuente del sistema.
class AppText {
  AppText._();

  /// Títulos: Syne 800, letter-spacing -0.03em (h1,h2,h3 de la referencia).
  static TextStyle syne(double size,
      {Color color = AppColors.textPrimary,
      FontWeight weight = FontWeight.w800}) {
    return GoogleFonts.syne(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.03 * size,
      height: 1.1,
    );
  }

  /// Cuerpo: DM Sans (body de la referencia, line-height 1.55).
  static TextStyle body(double size,
      {Color color = AppColors.textPrimary,
      FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.dmSans(
        fontSize: size, fontWeight: weight, color: color, height: 1.45);
  }

  /// Etiquetas técnicas: JetBrains Mono uppercase con tracking ancho
  /// (.brand-sub, .section-kicker, .nav-tab, .gscorelabel de la referencia).
  static TextStyle mono(double size,
      {Color color = AppColors.textTertiary,
      FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.12 * size,
    );
  }
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.background,
    primary: AppColors.lime,
    secondary: AppColors.cyan,
    error: AppColors.error,
  );

  final dmSans = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
    textTheme: dmSans.copyWith(
      titleLarge: AppText.syne(22),
      titleMedium: AppText.syne(16),
      bodyLarge: AppText.body(15),
      bodyMedium: AppText.body(13.5, color: AppColors.textSecondary),
      bodySmall: AppText.body(12, color: AppColors.textTertiary),
      labelLarge: AppText.body(14, weight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background.withValues(alpha: 0.88),
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppText.syne(18),
    ),
    dividerColor: AppColors.border1,
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.lime,
      inactiveTrackColor: AppColors.border2,
      thumbColor: AppColors.lime,
      overlayColor: AppColors.lime.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.lime
            : AppColors.textTertiary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.lime.withValues(alpha: 0.28)
            : AppColors.surface3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: const Color(0xFF111111),
        textStyle: AppText.body(13, weight: FontWeight.w800)
            .copyWith(letterSpacing: 0.8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface3,
        side: const BorderSide(color: AppColors.border1),
        textStyle: AppText.body(13, weight: FontWeight.w800),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface3,
      hintStyle: AppText.body(14, color: AppColors.textTertiary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.border1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: const BorderSide(color: AppColors.cyan),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    ),
  );
}
