import 'package:bizagent/features/dashboard/widgets/smart_dashboard_empty_state.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SmartDashboardEmptyState renders correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SmartDashboardEmptyState(),
          ),
        ),
      ),
    );

    // Verify main text
    expect(find.text('Vitajte v BizAgent!'), findsOneWidget);
    expect(find.text('Pripravte svoju firmu na úspech'), findsOneWidget);

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
}
