import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/core/i18n/l10n.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Dashboard shows first-run banner when invoices & expenses are empty',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {}); // Mock SP for TutorialService check
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid real Firebase/Auth calls in tests
          authStateProvider.overrideWith((ref) => Stream.value(null)),

          // Ensure first-run empty state
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const L10n(
          locale: AppLocale.sk,
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      ),
    );

    // Avoid pumpAndSettle due to infinite animations on the dashboard.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify Smart Dashboard Empty State is present
    expect(find.text('Vitajte v BizAgent!'), findsOneWidget);
    expect(find.text('Pripravte svoju firmu na úspech'), findsOneWidget);

    // Verify Checklist Items
    expect(find.text('Nastaviť firemné údaje'), findsOneWidget);
    expect(find.text('Vytvoriť prvú faktúru'), findsOneWidget);
    expect(find.text('Pridať prvý výdavok'), findsOneWidget);

    // Verify Icons exist
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    expect(find.byIcon(Icons.business), findsOneWidget);

    // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
    await tester.pump(const Duration(seconds: 3));
  });
}
