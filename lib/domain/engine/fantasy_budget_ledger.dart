/// Libro de caja de una temporada Fantasy.
///
/// Las variaciones de precio cambian el valor vendible del equipo, mientras
/// que el efectivo no cambia hasta realizar traspasos. Por eso el tope real
/// de una ronda es `efectivo + valor actual de los siete activos`, no 100 M$
/// recalculados en cada GP.
class FantasyBudgetLedger {
  const FantasyBudgetLedger._(this.cashMillions);

  factory FantasyBudgetLedger.initial({
    required double startingBudgetMillions,
    required double teamCostMillions,
  }) {
    return FantasyBudgetLedger._(
      startingBudgetMillions - teamCostMillions,
    );
  }

  final double cashMillions;

  double purchasingPower(double currentTeamValueMillions) =>
      cashMillions + currentTeamValueMillions;

  FantasyBudgetLedger afterTransfers({
    required double currentTeamValueMillions,
    required double resultingTeamCostMillions,
  }) {
    return FantasyBudgetLedger._(
      purchasingPower(currentTeamValueMillions) - resultingTeamCostMillions,
    );
  }
}
