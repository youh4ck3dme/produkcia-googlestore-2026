import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bizagent/features/analytics/models/expense_insight_model.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/dashboard/widgets/smart_insights_widget.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/shared/widgets/biz_shimmer.dart';

void main() {
  group('SmartInsightsWidget', () {
    testWidgets('should display loading state', (tester) async {
      final completer = Completer<List<ExpenseInsight>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => completer.future),
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

      expect(find.byType(BizShimmer), findsOneWidget);
    });

    testWidgets('should display insight card when data is available',
        (tester) async {
      final mockInsights = [
        ExpenseInsight(
          id: '1',
          title: 'Test Insight',
          description: 'This is a test insight description',
          icon: Icons.lightbulb,
          color: Colors.blue,
          priority: InsightPriority.medium,
          createdAt: DateTime.now(),
          category: 'test',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => mockInsights),
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

      await tester.pump();

      expect(find.text('Test Insight'), findsOneWidget);
      expect(find.text('This is a test insight description'), findsOneWidget);
      expect(find.text('AI POSTREH'), findsOneWidget);
    });

    testWidgets('should display high priority badge for high priority insights',
        (tester) async {
      final mockInsights = [
        ExpenseInsight(
          id: '1',
          title: 'High Priority Insight',
          description: 'This is a high priority insight',
          icon: Icons.warning,
          color: Colors.red,
          priority: InsightPriority.high,
          createdAt: DateTime.now(),
          category: 'test',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => mockInsights),
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

      await tester.pump();
      expect(find.text('DÔLEŽITÉ'), findsOneWidget);
    });

    testWidgets('should display potential savings when available',
        (tester) async {
      final mockInsights = [
        ExpenseInsight(
          id: '1',
          title: 'Savings Insight',
          description: 'This insight has potential savings',
          icon: Icons.savings,
          color: Colors.green,
          priority: InsightPriority.medium,
          potentialSavings: 150.0,
          createdAt: DateTime.now(),
          category: 'optimization',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => mockInsights),
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

      await tester.pump();
      // Current widget shows a "+12%" badge when potentialSavings is present.
      expect(find.text('+12%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsWidgets);
    });

    testWidgets('should be hidden when no insights are available',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => []),
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

      await tester.pump();
      expect(find.byType(SmartInsightsWidget), findsOneWidget);
      // It returns SizedBox.shrink() inside the widget, so its height should be 0 or find nothing rendered
      final container = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(container.width, 0);
      expect(container.height, 0);
    });

    testWidgets('should be tappable and navigate on tap', (tester) async {
      final mockInsights = [
        ExpenseInsight(
          id: '1',
          title: 'Tappable Insight',
          description: 'This insight should be tappable',
          icon: Icons.touch_app,
          color: Colors.blue,
          priority: InsightPriority.medium,
          createdAt: DateTime.now(),
          category: 'test',
        ),
      ];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: SmartInsightsWidget()),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) =>
                const Scaffold(body: Text('Analytics Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseInsightsProvider.overrideWith((ref) => mockInsights),
          ],
          child: L10n(
            locale: AppLocale.sk,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap the insight card
      await tester.tap(find.text('Tappable Insight'));
      await tester.pumpAndSettle();

      // Should navigate to analytics screen
      expect(find.text('Analytics Screen'), findsOneWidget);
    });
  });
}
