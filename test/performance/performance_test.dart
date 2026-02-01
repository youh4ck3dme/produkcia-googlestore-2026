import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';

void main() {
  group('Performance Benchmarks', () {
    test('expense generation under 500ms', () async {
      final stopwatch = Stopwatch()..start();
      DemoDataGenerator.generateExpenses(DemoScenario.standard);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'generateExpenses should complete under 500ms');
    });

    test('insight generation under 500ms', () async {
      final stopwatch = Stopwatch()..start();
      DemoDataGenerator.generateInsights(DemoScenario.taxOptimization);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'generateInsights should complete under 500ms');
    });

    test('invoice generation under 500ms', () async {
      final stopwatch = Stopwatch()..start();
      DemoDataGenerator.generateInvoices(DemoScenario.standard);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'generateInvoices should complete under 500ms');
    });

    test('large dataset 1000 expenses under 3 seconds', () async {
      final stopwatch = Stopwatch()..start();
      final list = DemoDataGenerator.generateLargeDataset(1000);
      stopwatch.stop();
      expect(list.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'generateLargeDataset(1000) should complete under 3s');
    });

    test('all scenarios expense generation under 2 seconds', () async {
      final stopwatch = Stopwatch()..start();
      for (final scenario in DemoScenario.values) {
        DemoDataGenerator.generateExpenses(scenario);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'All scenarios expense generation under 2s');
    });
  });
}
