import 'dart:io';

import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_mode_service.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import '../../helpers/demo_test_skip.dart';

/// Hive + [DemoModeService] — stabilita demo dát a Play review guard.
void main() {
  group('DemoModeService + LocalPersistenceService (Hive)', () {
    late Directory tempDir;
    late LocalPersistenceService persistence;
    final demo = DemoModeService.instance;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('demo_mode_hive_');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    setUp(() async {
      persistence = LocalPersistenceService();
      await persistence.init();
      await persistence.clearAll();
      await demo.resetForTesting();
      demo.persistence = persistence;
    });

    tearDown(() async {
      DemoModeService.debugSimulateReleaseMode = false;
      await demo.resetForTesting();
      await persistence.clearAll();
    });

    test('activateDemoMode naplní Hive a zapne isDemoMode', () async {
      await demo.activateDemoMode(DemoScenario.standard);

      expect(demo.isDemoMode, isTrue);
      expect(demo.currentScenario, DemoScenario.standard);

      final expectedInvoices =
          DemoDataGenerator.generateInvoices(DemoScenario.standard);
      final expectedExpenses =
          DemoDataGenerator.generateExpenses(DemoScenario.standard);

      final invoices = persistence.getInvoices();
      final expenses = persistence.getExpenses();

      expect(invoices.length, expectedInvoices.length);
      expect(expenses.length, expectedExpenses.length);

      for (final invoice in expectedInvoices) {
        expect(
          invoices.any((row) => row['id'] == invoice.id),
          isTrue,
          reason: 'Chýba faktúra ${invoice.id} v Hive',
        );
      }
      for (final expense in expectedExpenses) {
        expect(
          expenses.any((row) => row['id'] == expense.id),
          isTrue,
          reason: 'Chýba výdavok ${expense.id} v Hive',
        );
      }

      expect(
        invoices.every((row) => (row['id'] as String).startsWith('demo_')),
        isTrue,
      );
      expect(
        expenses.every((row) => (row['id'] as String).startsWith('demo_')),
        isTrue,
      );
    }, skip: skipDemoMutationTests);

    test('deactivateDemoMode vyčistí Hive a vypne isDemoMode', () async {
      await demo.activateDemoMode(DemoScenario.approachingVat);
      expect(persistence.getInvoices(), isNotEmpty);
      expect(persistence.getExpenses(), isNotEmpty);

      await demo.deactivateDemoMode();

      expect(demo.isDemoMode, isFalse);
      expect(demo.currentScenario, DemoScenario.standard);
      expect(persistence.getInvoices(), isEmpty);
      expect(persistence.getExpenses(), isEmpty);
      expect(demo.getDemoInvoices(), isEmpty);
      expect(demo.getDemoExpenses(), isEmpty);
    }, skip: skipDemoMutationTests);

    test('release guard: žiadna injekcia bez vedomej aktivácie (kReleaseMode)', () async {
      DemoModeService.debugSimulateReleaseMode = true;

      await demo.activateDemoMode(DemoScenario.standard);

      expect(demo.isDemoMode, isFalse);
      expect(persistence.getInvoices(), isEmpty);
      expect(persistence.getExpenses(), isEmpty);
      expect(demo.getDemoInvoices(), isEmpty);
      expect(demo.getDemoExpenses(), isEmpty);
    });
  });
}
