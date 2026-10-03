import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp_fantasy_advisor/ui/widgets/lazy_tab_stack.dart';

void main() {
  testWidgets('hidden tabs start only on first visit and retain form state', (
    tester,
  ) async {
    var secondBuilds = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final tabs = [
      TextField(controller: controller),
      Builder(
        builder: (_) {
          secondBuilds++;
          return const Text('Plan');
        },
      ),
    ];
    Future<void> show(int index) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyTabStack(index: index, children: tabs),
        ),
      ),
    );
    await show(0);
    await tester.enterText(find.byType(TextField), 'Equipo');
    expect(secondBuilds, 0);
    await show(1);
    expect(secondBuilds, 1);
    await show(0);
    expect(controller.text, 'Equipo');
    expect(secondBuilds, 1);
  });
}
