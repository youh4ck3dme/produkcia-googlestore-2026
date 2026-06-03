import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/demo_mode/demo_data_generator.dart';
import 'package:bizagent/core/demo_mode/demo_scenarios.dart';
import 'package:bizagent/features/dashboard/widgets/smart_insights_widget.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
// Use ThemeData to avoid google_fonts network load in tests
import 'package:bizagent/core/i18n/l10n.dart';

void main() {
  // Goldens were captured on macOS; Ubuntu CI rasterizes fonts differently.
  final skipOnLinuxCi = Platform.isLinux;

  group('Golden Tests - UI Screenshots', () {
    testWidgets('SmartInsightsWidget with demo insight matches golden', (tester) async {
      final demoInsights = DemoDataGenerator.generateInsights(DemoScenario.standard);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => Future.value(demoInsights)),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const L10n(
              locale: AppLocale.sk,
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: SmartInsightsWidget(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SmartInsightsWidget),
        matchesGoldenFile('goldens/smart_insights_widget.png'),
      );
    }, skip: skipOnLinuxCi ? 'Linux CI font raster differs from macOS goldens' : false);

    testWidgets('SmartInsightsWidget dark theme matches golden', (tester) async {
      final demoInsights = DemoDataGenerator.generateInsights(DemoScenario.taxOptimization);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => Future.value(demoInsights)),
          ],
          child: MaterialApp(
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: const L10n(
              locale: AppLocale.sk,
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: SmartInsightsWidget(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SmartInsightsWidget),
        matchesGoldenFile('goldens/smart_insights_widget_dark.png'),
      );
    }, skip: skipOnLinuxCi ? 'Linux CI font raster differs from macOS goldens' : false);
  });
}
