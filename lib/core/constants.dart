/// Reglas del juego F1 Fantasy 2026 (PLAN_DESARROLLO.md, sección 2).
/// Verificar contra fantasy.formula1.com al inicio del proyecto: pueden cambiar.
class GameRules {
  GameRules._();

  static const double initialBudgetMillions = 100.0;
  static const int driversPerTeam = 5;
  static const int constructorsPerTeam = 2;
  static const int freeTransfersPerRound = 2;
  static const int extraTransferPenalty = -10;
  static const double minPrice = 3.0;
  static const double maxPrice = 34.0;
  static const double priceStepBelowThreshold = 0.6;
  static const double priceStepAboveThreshold = 0.3;
  static const double priceThreshold = 18.5;
  static const int priceChangeWindowRaces = 3;
  static const int weeklyBoostMultiplier = 2;

  static const List<String> chipNames = [
    'Limitless',
    'Wildcard',
    '3x Boost',
    'No Negative',
    'Final Fix',
    'Autopilot',
  ];
}

class AssetPaths {
  AssetPaths._();

  static const String scoringTable = 'assets/scoring_2026.json';
  static const String modelWeights = 'assets/model_weights.json';
  static const String remoteConfigFallback =
      'assets/remote_config_fallback.json';
  static const String driverStandingsFallback =
      'assets/driver_standings_2026.json';
  static const String constructorStandingsFallback =
      'assets/constructor_standings_2026.json';
}

class AppMeta {
  AppMeta._();

  static const String appName = 'Polewise';
  static const String appVersion = '1.3.1';
  static const String developerName = String.fromEnvironment(
    'POLEWISE_DEVELOPER_NAME',
    defaultValue: 'Polewise',
  );
  static const String supportEmail = String.fromEnvironment(
    'POLEWISE_SUPPORT_EMAIL',
    defaultValue: '',
  );
  static const String privacyPolicyUrl = String.fromEnvironment(
    'POLEWISE_PRIVACY_URL',
    defaultValue:
        'https://huisvis127.github.io/gp-fantasy-advisor/privacy-policy.html',
  );
  static const String disclaimer =
      'Polewise es una aplicación no oficial y no está asociada de ninguna '
      'manera con las compañías de Formula 1. F1, FORMULA ONE, FORMULA 1, '
      'FIA FORMULA ONE WORLD CHAMPIONSHIP, GRAND PRIX y las marcas '
      'relacionadas son marcas comerciales de Formula One Licensing B.V.';
}
