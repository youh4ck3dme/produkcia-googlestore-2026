import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/tax/screens/cashflow_analytics_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';

void main() {
  testWidgets('CashflowAnalyticsScreen displays title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: CashflowAnalyticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Analytika Cashflow'), findsOneWidget);

    // Verify chart titles are present
    expect(find.text('Príjmy vs Výdavky (6 mesiacov)'), findsOneWidget);
    expect(find.text('Rozdelenie výdavkov'), findsOneWidget);
  });

  testWidgets('CashflowAnalyticsScreen shows loading indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoicesProvider.overrideWith((ref) => const Stream.empty()),
          expensesProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: CashflowAnalyticsScreen(),
        ),
      ),
    );

    // Should show loading initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
