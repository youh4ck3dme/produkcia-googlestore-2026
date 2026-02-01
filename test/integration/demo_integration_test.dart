import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/demo_mode/demo_mode.dart';

/// Integration-style test: demo mode service + data generator together.
void main() {
  group('Demo integration', () {
    test('DemoScenarioRunner runs full demo without throwing', () async {
      final runner = DemoScenarioRunner.instance;
      await expectLater(
        runner.runFullDemo(),
        completes,
      );
    });

    test('Demo mode data is consistent across getters', () {
      final demo = DemoModeService.instance;
      demo.activateDemoMode(DemoScenario.approachingVat);

      final expenses = demo.getDemoExpenses();
      final invoices = demo.getDemoInvoices();
      final insights = demo.getDemoInsights();

      expect(expenses, isNotEmpty);
      expect(invoices, isNotEmpty);
      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.title.contains('DPH') || i.title.contains('limitu')), isTrue);

      demo.deactivateDemoMode();
    });
  });
}
