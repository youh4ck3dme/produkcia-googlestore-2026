import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_mode.dart';
import 'package:bizagent/features/dashboard/widgets/smart_insights_widget.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import '../helpers/demo_test_skip.dart';

void main() {
  group('AI Accountant E2E Tests', () {
    late DemoModeService demoService;

    setUp(() {
      demoService = DemoModeService.instance;
      demoService.deactivateDemoMode();
    });

    test('DemoModeService activates and returns demo insights', () {
      demoService.activateDemoMode(DemoScenario.standard);
      expect(demoService.isDemoMode, isTrue);
      final insights = demoService.getDemoInsights();
      expect(insights, isNotEmpty);
      expect(insights.first.title, contains('Predikcia'));
      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);

    test('tax_optimization scenario returns savings insight', () {
      demoService.activateDemoMode(DemoScenario.taxOptimization);
      final insights = demoService.getDemoInsights();
      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.potentialSavings != null), isTrue);
      expect(insights.any((i) => i.title.toLowerCase().contains('úspor') || i.description.contains('ušetri')), isTrue);
      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);

    test('anomaly_detection scenario returns anomaly insights', () {
      demoService.activateDemoMode(DemoScenario.anomalyDetection);
      final insights = demoService.getDemoInsights();
      expect(insights.length, greaterThanOrEqualTo(1));
      expect(insights.any((i) => i.category == 'anomaly' || i.title.toLowerCase().contains('podozriv')), isTrue);
      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);

    testWidgets('SmartInsightsWidget displays demo insight', (tester) async {
      final demoInsights = DemoDataGenerator.generateInsights(DemoScenario.standard);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => Future.value(demoInsights)),
          ],
          child: const MaterialApp(
            home: L10n(
              locale: AppLocale.sk,
              child: Scaffold(
                body: SmartInsightsWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(demoInsights.first.title), findsOneWidget);
      expect(find.textContaining('Predikcia'), findsWidgets);
    });

    testWidgets('SmartInsightsWidget shows tax recommendation text when tax scenario', (tester) async {
      final demoInsights = DemoDataGenerator.generateInsights(DemoScenario.taxOptimization);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => Future.value(demoInsights)),
          ],
          child: const MaterialApp(
            home: L10n(
              locale: AppLocale.sk,
              child: Scaffold(
                body: SmartInsightsWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(demoInsights.first.title), findsOneWidget);
      expect(find.byType(SmartInsightsWidget), findsOneWidget);
    });

    test('generateInsights returns valid structure for notification', () {
      demoService.activateDemoMode(DemoScenario.standard);
      final insights = demoService.getDemoInsights();
      expect(insights, isNotEmpty);
      final first = insights.first;
      expect(first.title, isNotEmpty);
      expect(first.description, isNotEmpty);
      expect(first.description.contains('€') || first.title.contains('Predikcia'), isTrue);
      demoService.deactivateDemoMode();
    }, skip: skipDemoMutationTests);
  });
}
