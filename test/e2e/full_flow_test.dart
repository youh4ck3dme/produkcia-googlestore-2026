import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/demo_mode/demo_mode.dart';
import '../helpers/demo_test_skip.dart';

void main() {
  group('Full Flow / Demo Mode E2E', () {
    late DemoModeService demoService;

    setUp(() {
      demoService = DemoModeService.instance;
      demoService.deactivateDemoMode();
    });

    test('demo mode off returns empty demo data', () {
      expect(demoService.isDemoMode, isFalse);
      expect(demoService.getDemoExpenses(), isEmpty);
      expect(demoService.getDemoInvoices(), isEmpty);
      expect(demoService.getDemoInsights(), isEmpty);
    });

    test('activateDemoMode provides data for all scenarios', () {
      for (final scenario in DemoScenario.values) {
        demoService.activateDemoMode(scenario);
        expect(demoService.isDemoMode, isTrue);
        expect(demoService.currentScenario, scenario);

        final expenses = demoService.getDemoExpenses();
        final invoices = demoService.getDemoInvoices();
        final insights = demoService.getDemoInsights();

        expect(expenses, isNotEmpty, reason: 'scenario $scenario');
        expect(invoices, isNotEmpty, reason: 'scenario $scenario');
        expect(insights, isNotEmpty, reason: 'scenario $scenario');
      }
      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);

    test('DemoDataGenerator standard scenario has valid expenses and invoices', () {
      final expenses = DemoDataGenerator.generateExpenses(DemoScenario.standard);
      final invoices = DemoDataGenerator.generateInvoices(DemoScenario.standard);

      expect(expenses.length, greaterThan(10));
      expect(invoices.length, 6);

      for (final e in expenses) {
        expect(e.id, isNotEmpty);
        expect(e.amount, greaterThan(0));
        expect(e.date.isBefore(DateTime.now().add(const Duration(days: 1))), isTrue);
      }
      for (final i in invoices) {
        expect(i.id, isNotEmpty);
        expect(i.items, isNotEmpty);
        expect(i.totalAmount, greaterThan(0));
      }
    });

    test('triple-tap simulation toggles demo mode', () {
      expect(demoService.isDemoMode, isFalse);
      demoService.recordLogoTap();
      demoService.recordLogoTap();
      demoService.recordLogoTap();
      expect(demoService.isDemoMode, isTrue);
      demoService.recordLogoTap();
      demoService.recordLogoTap();
      demoService.recordLogoTap();
      expect(demoService.isDemoMode, isFalse);
    }, skip: skipDemoMutationTests);

    test('setScenario changes current scenario without deactivating', () {
      demoService.activateDemoMode(DemoScenario.standard);
      expect(demoService.currentScenario, DemoScenario.standard);

      demoService.setScenario(DemoScenario.taxOptimization);
      expect(demoService.isDemoMode, isTrue);
      expect(demoService.currentScenario, DemoScenario.taxOptimization);
      expect(demoService.getDemoInsights().first.title, isNotEmpty);

      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);
  });
}
