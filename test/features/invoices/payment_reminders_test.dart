import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/invoices/screens/payment_reminders_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';

void main() {
  testWidgets('PaymentRemindersScreen displays empty state when no invoices',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          invoicesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: PaymentRemindersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Žiadne faktúry po splatnosti! 🎉'), findsOneWidget);
  });

  // Note: testing with actual overdue invoices requires mocking the InvoiceModel list
  // and ensuring dates are set correctly relative to "now".
  // For a robust test, we would need to mock the system time or just use dates far in the past.
}
