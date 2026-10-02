import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño extraído 1:1 del index.html de la app de referencia
/// ("Fantasy Advisor" MotoGP, docs/archive/PLAN_DESARROLLO.md sección 1.1 y 6).
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

  // La raíz sincroniza estos tokens con el tema elegido. Los widgets que los
  // usan se suscriben a Theme.of(context) para actualizarse al cambiar de modo.
  static Brightness brightness = Brightness.dark;
  static bool get isLight => brightness == Brightness.light;

  static Color get background =>
      isLight ? const Color(0xFFF5F6FA) : const Color(0xFF08080B); // --bg
  static Color get background2 =>
      isLight ? const Color(0xFFEEF1F6) : const Color(0xFF0B0B10); // --bg-2
  static Color get surface1 =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF101015);
  static Color get surface2 =>
      isLight ? const Color(0xFFF9FAFC) : const Color(0xFF16161D);
  static Color get surface3 =>
      isLight ? const Color(0xFFEDF0F5) : const Color(0xFF1E1E25);
  static Color get surface4 =>
      isLight ? const Color(0xFFE1E6EF) : const Color(0xFF262631);

  static Color get textPrimary =>
      isLight ? const Color(0xFF192234) : const Color(0xFFF9F9FB); // --t1
  static Color get textSecondary =>
      isLight ? const Color(0xFF4E5B70) : const Color(0xFFA0A0B0); // --t2
  static Color get textTertiary =>
      isLight ? const Color(0xFF637086) : const Color(0xFF606070); // --t3

  static Color get border1 => isLight
      ? const Color(0xFFDCE2EC)
      : const Color(0x14FFFFFF); // rgba(255,255,255,.08)
  static Color get border2 => isLight
      ? const Color(0xFFC6CFDD)
      : const Color(0x24FFFFFF); // rgba(255,255,255,.14)
  static Color get glassFill => isLight
      ? const Color(0xFFFFFFFF)
      : const Color(0x0AFFFFFF); // --glass .04
  static Color get glassStrong => isLight
      ? const Color(0xFFEEF1F6)
      : const Color(0x12FFFFFF); // --glass-strong .07

  // Se conservan los nombres internos `lime`/`lime2` para no romper widgets
  // existentes; visualmente son ahora el rojo principal de la app F1.
  static Color get lime =>
      isLight ? const Color(0xFFD51132) : const Color(0xFFFF1838);
  static Color get lime2 =>
      isLight ? const Color(0xFFCB2546) : const Color(0xFFFF5268);
  static Color get cyan =>
      isLight ? const Color(0xFF00788D) : const Color(0xFF00E5FF);
  static Color get magenta =>
      isLight ? const Color(0xFFBA207E) : const Color(0xFFFF3CB8);
  static Color get violet =>
      isLight ? const Color(0xFF7138C4) : const Color(0xFF9B5CFF);
  static Color get orange =>
      isLight ? const Color(0xFFBD5100) : const Color(0xFFFF7000);
  static Color get gold =>
      isLight ? const Color(0xFF976C00) : const Color(0xFFFFD700);
  static Color get silver =>
      isLight ? const Color(0xFF65738A) : const Color(0xFFC7C9D6);

  static Color get ok =>
      isLight ? const Color(0xFF007B57) : const Color(0xFF00E096);
  static Color get warning =>
      isLight ? const Color(0xFF996000) : const Color(0xFFFFB833);
  static Color get error =>
      isLight ? const Color(0xFFC92346) : const Color(0xFFFF4466);

  // Alias usados por widgets antiguos (compatibilidad).
  static Color get glassBorder => border1;
  static Color get accentCyan => cyan;
  static Color get accentLime => lime;
  static Color get accentMagenta => magenta;
  static Color get accentViolet => violet;
  static Color get accentOrange => orange;
  static Color get backgroundDeep => background;
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
  static TextStyle syne(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.syne(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.03 * size,
      height: 1.1,
    );
  }

  /// Cuerpo: DM Sans (body de la referencia, line-height 1.55).
  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.45,
    );
  }

  /// Etiquetas técnicas: JetBrains Mono uppercase con tracking ancho
  /// (.brand-sub, .section-kicker, .nav-tab, .gscorelabel de la referencia).
  static TextStyle mono(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textTertiary,
      letterSpacing: 0.12 * size,
    );
  }
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.lime,
    brightness: AppColors.brightness,
    surface: AppColors.background,
    primary: AppColors.lime,
    secondary: AppColors.cyan,
    error: AppColors.error,
  );

  final dmSans = GoogleFonts.dmSansTextTheme(
    (AppColors.isLight ? ThemeData.light() : ThemeData.dark()).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: AppColors.brightness,
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
        foregroundColor: AppColors.isLight
            ? Colors.white
            : const Color(0xFF111111),
        textStyle: AppText.body(
          13,
          weight: FontWeight.w800,
        ).copyWith(letterSpacing: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface3,
        side: BorderSide(color: AppColors.border1),
        textStyle: AppText.body(13, weight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface3,
      hintStyle: AppText.body(14, color: AppColors.textTertiary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide(color: AppColors.border1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide(color: AppColors.cyan),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    ),
  );
}
