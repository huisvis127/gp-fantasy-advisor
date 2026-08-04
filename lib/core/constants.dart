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
    'Triple Boost',
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

  static const String appName = 'GP Fantasy Advisor';
  static const String disclaimer =
      'App no oficial. No afiliada a Formula One Licensing B.V.';
}
