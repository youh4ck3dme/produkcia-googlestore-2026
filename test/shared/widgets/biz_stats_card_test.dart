import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/shared/widgets/biz_widgets.dart';

void main() {
  group('BizStatsCard Widget Test', () {
    testWidgets('BizStatsCard displays metric and icon', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Tržby',
            metric: '12 500 €',
            icon: Icons.attach_money,
          ),
        ),
      ));

      // Let flutter_animate settle.
      await tester.pumpAndSettle();

      expect(find.text('TRŽBY'), findsOneWidget);
      expect(find.text('12 500 €'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      // Clear any delayed timers before teardown.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('BizStatsCard displays positive trend correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Zisk',
            metric: '5 000 €',
            icon: Icons.trending_up,
            trend: '+15%',
            isPositive: true,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('+15%'), findsOneWidget);
      // Icon appears in the card (main) and in the trend badge.
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('BizStatsCard displays negative trend correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Náklady',
            metric: '2 000 €',
            icon: Icons.trending_down,
            trend: '-5%',
            isPositive: false,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('-5%'), findsOneWidget);
      // Icon appears in the card (main) and in the trend badge.
      expect(find.byIcon(Icons.trending_down), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
