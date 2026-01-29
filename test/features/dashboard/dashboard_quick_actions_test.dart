import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/core/i18n/l10n.dart';

void main() {
  testWidgets('Dashboard shows 5 quick action tiles when empty state is active',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Avoid real Firebase/Auth calls in tests
          authStateProvider.overrideWith((ref) => Stream.value(null)),

          // Ensure empty state to show quick actions
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

    // Scroll down to the Quick Actions section (ListView content may be off-screen).
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Rýchle akcie'),
      300,
      scrollable: scrollable,
    );
    await tester.pump();

    // Verify "Rýchle akcie" section header
    expect(find.text('Rýchle akcie'), findsOneWidget);

    // Verify all 5 quick action tiles are present
    // 1. Nová faktúra
    expect(find.text('Faktúra'), findsOneWidget);
    expect(find.text('Nová faktúra pre klienta'), findsOneWidget);

    // 2. Skenovať bloček
    expect(find.text('✨ Magic Scan'), findsOneWidget);
    expect(find.text('AI vyčítanie a automatické vyplnenie'), findsOneWidget);

    // 3. Pridať výdavok
    expect(find.text('Pridať výdavok'),
        findsAtLeastNWidgets(1)); // May appear in banner too
    expect(find.text('Evidencia nákladov'), findsOneWidget);

    // 4. Import bank CSV
    expect(find.text('Import bank CSV'), findsOneWidget);
    expect(find.text('Automatické párovanie faktúr'), findsOneWidget);

    // 5. Export pre účtovníka
    expect(find.text('Export pre účtovníka'), findsOneWidget);
    expect(find.text('Zostava faktúr a výdavkov'), findsOneWidget);

    // Verify action tiles use the trailing arrow icon.
    final trailingIcons = find.byIcon(Icons.arrow_forward_ios_rounded);
    expect(trailingIcons, findsAtLeastNWidgets(5));

    // Let any delayed flutter_animate timers fire to avoid timersPending at teardown.
    await tester.pump(const Duration(seconds: 3));
  });
}
