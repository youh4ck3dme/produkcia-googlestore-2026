import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:bizagent/shared/widgets/biz_widgets.dart'; // Correct package import

void main() {
  group('BizInvoiceCard Widget Test', () {
    testWidgets('BizInvoiceCard displays correct info', (WidgetTester tester) async {
      final date = DateTime(2025, 12, 31);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BizInvoiceCard(
            title: 'Firma XYZ',
            subtitle: 'FA-2025001',
            amount: 150.50,
            date: date,
            status: 'Odoslaná',
            onTap: (){},
          ),
        ),
      ));

      // Let flutter_animate and formatting settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Verify Texts
      expect(find.text('Firma XYZ', skipOffstage: false), findsOneWidget);
      expect(find.text('FA-2025001', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('150', skipOffstage: false), findsOneWidget);

      // 2. Verify Semantics
      final handle = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Faktúra\s+FA-2025001\s+pre\s+Firma\s+XYZ,\s*suma\s+.*150.*(€|EUR),\s*dátum\s+31\.12\.2025',
          ),
        ),
        findsOneWidget,
      );

      // Tap action should be available via InkWell semantics.
      final inkWellFinder = find.descendant(
        of: find.byType(BizInvoiceCard, skipOffstage: false),
        matching: find.byType(InkWell),
      );
      final data = tester.getSemantics(inkWellFinder).getSemanticsData();
      expect(data.flagsCollection.isButton, true);
      expect(data.hasAction(SemanticsAction.tap), true);
      handle.dispose();

      // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
      await tester.pump(const Duration(seconds: 3));

      // Ensure all pending timers from flutter_animate are cleared before teardown.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
