import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/ui/widgets/ref_widgets.dart';

void main() {
  testWidgets('las métricas largas del plan no desbordan en alemán', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(360, 800)),
          child: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: TotalPill(value: '319', label: 'Pkt. im Horizont'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TotalPill(
                    value: '-4.5 M\$',
                    label: 'prognostizierter Wert',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
