import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/domain/engine/fantasy_budget_ledger.dart';

void main() {
  test('conserva efectivo y añade la subida de valor al presupuesto', () {
    var ledger = FantasyBudgetLedger.initial(
      startingBudgetMillions: 100,
      teamCostMillions: 98,
    );

    expect(ledger.cashMillions, 2);
    expect(ledger.purchasingPower(103), 105);

    ledger = ledger.afterTransfers(
      currentTeamValueMillions: 103,
      resultingTeamCostMillions: 101,
    );
    expect(ledger.cashMillions, 4);
    expect(ledger.purchasingPower(102), 106);
  });

  test('una bajada de precios reduce el tope; no lo reinicia a 100', () {
    final ledger = FantasyBudgetLedger.initial(
      startingBudgetMillions: 100,
      teamCostMillions: 99,
    );

    expect(ledger.purchasingPower(94), 95);
  });
}
