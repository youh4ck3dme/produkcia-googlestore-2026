import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:bizagent/core/config/product_copy.dart';
import 'package:bizagent/features/dashboard/widgets/smart_dashboard_empty_state.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/layout_test_helpers.dart';

Widget buildEmptyState({
  UserSettingsModel? settings,
  List<InvoiceModel>? invoices,
  List<ExpenseModel>? expenses,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(
        (ref) => Stream.value(settings ?? UserSettingsModel.empty()),
      ),
      invoicesProvider.overrideWith(
        (ref) => Stream.value(invoices ?? []),
      ),
      expensesProvider.overrideWith(
        (ref) => Stream.value(expenses ?? []),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SmartDashboardEmptyState(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('SmartDashboardEmptyState renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildEmptyState());

    // Verify main text (Play MVP používa ProductCopy)
    final title = PlayReleaseScope.playMvp
        ? ProductCopy.emptyStateTitle
        : 'Vitajte v BizAgent!';
    final subtitle = PlayReleaseScope.playMvp
        ? ProductCopy.emptyStateSubtitle
        : 'Pripravte svoju firmu na úspech';

    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);

    // Verify checklist items
    expect(find.text('Nastaviť firemné údaje'), findsOneWidget);
    expect(find.text('Vytvoriť prvú faktúru'), findsOneWidget);
    expect(find.text('Pridať prvý výdavok'), findsOneWidget);

    // Verify icons
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    expect(find.byIcon(Icons.business), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('shows completion checkmarks when onboarding steps are done',
      (WidgetTester tester) async {
    final now = DateTime(2026, 1, 1);
    await tester.pumpWidget(
      buildEmptyState(
        settings: UserSettingsModel.empty().copyWith(
          companyName: 'Test s.r.o.',
          companyIco: '12345678',
        ),
        invoices: [
          InvoiceModel(
            id: 'inv-1',
            userId: 'u1',
            createdAt: now,
            number: '2026001',
            clientName: 'Klient',
            dateIssued: now,
            dateDue: now.add(const Duration(days: 14)),
            items: const [],
            totalAmount: 100,
            status: InvoiceStatus.draft,
          ),
        ],
        expenses: [
          ExpenseModel(
            id: 'exp-1',
            userId: 'u1',
            vendorName: 'Obchod',
            description: 'Kancelárske potreby',
            amount: 25,
            date: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNWidgets(3));
  });

  testWidgets('avoids horizontal overflow on narrow viewports',
      (WidgetTester tester) async {
    addTearDown(() => resetTestView(tester));
    for (final width in [150.0, 320.0, 400.0]) {
      await pumpAtViewport(
        tester,
        buildEmptyState(),
        physicalSize: Size(width, 700),
        textScaleFactor: 1.3,
      );
      expectNoLayoutOverflow(tester);
    }
  });
}
