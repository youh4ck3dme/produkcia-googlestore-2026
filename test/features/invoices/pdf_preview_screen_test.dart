import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/invoices/screens/pdf_preview_screen.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';

void main() {
  testWidgets('PdfPreviewScreen displays loading state',
      (WidgetTester tester) async {
    final testInvoice = InvoiceModel(
      id: 'test-1',
      userId: 'user-1',
      createdAt: DateTime.now(),
      number: '2026/001',
      clientName: 'Test Client',
      dateIssued: DateTime.now(),
      dateDue: DateTime.now().add(const Duration(days: 14)),
      items: [],
      totalAmount: 100.0,
      status: InvoiceStatus.draft,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
        ],
        child: MaterialApp(
          home: PdfPreviewScreen(invoice: testInvoice),
        ),
      ),
    );

    // Verify AppBar title
    expect(find.text('Náhľad faktúry 2026/001'), findsOneWidget);
  });
}
