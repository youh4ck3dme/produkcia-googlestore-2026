import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:bizagent/core/config/product_copy.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';

import '../../helpers/integration_harness.dart';
import '../../helpers/layout_test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpIntegrationHarness();
  });

  testWidgets(
      'Dashboard shows first-run banner when invoices & expenses are empty',
      (tester) async {
    addTearDown(() => resetTestView(tester));
    SharedPreferences.setMockInitialValues({});

    final title = PlayReleaseScope.playMvp
        ? ProductCopy.emptyStateTitle
        : 'Vitajte v BizAgent!';
    final subtitle = PlayReleaseScope.playMvp
        ? ProductCopy.emptyStateSubtitle
        : 'Pripravte svoju firmu na úspech';

    await pumpAtViewport(
      tester,
      integrationApp(child: const DashboardScreen()),
      physicalSize: const Size(390, 844),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text(title), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
    expect(find.text('Nastaviť firemné údaje'), findsOneWidget);
    expect(find.text('Vytvoriť prvú faktúru'), findsOneWidget);
    expect(find.text('Pridať prvý výdavok'), findsOneWidget);
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    expect(find.byIcon(Icons.business), findsOneWidget);
  });
}
