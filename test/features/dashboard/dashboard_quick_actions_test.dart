import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/config/play_release_scope.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';

import '../../helpers/integration_harness.dart';
import '../../helpers/layout_test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpIntegrationHarness();
  });

  testWidgets('Dashboard shows quick action tiles when empty state is active',
      (tester) async {
    addTearDown(() => resetTestView(tester));

    await pumpAtViewport(
      tester,
      integrationApp(child: const DashboardScreen()),
      physicalSize: const Size(390, 844),
    );

    await tester.pump(const Duration(seconds: 1));

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Rýchle akcie'),
      300,
      scrollable: scrollable,
    );
    await tester.pump();

    expect(find.text('Rýchle akcie'), findsOneWidget);
    expect(find.text('Faktúra'), findsOneWidget);
    expect(find.text('Nová faktúra pre klienta'), findsOneWidget);
    expect(find.text('Pridať výdavok'), findsAtLeastNWidgets(1));
    expect(find.text('Evidencia nákladov'), findsOneWidget);
    expect(find.text('Export pre účtovníka'), findsOneWidget);
    expect(find.text('Zostava faktúr a výdavkov'), findsOneWidget);

    if (PlayReleaseScope.showMagicScanQuickAction) {
      expect(find.text('✨ Magic Scan'), findsOneWidget);
      expect(find.text('AI vyčítanie a automatické vyplnenie'), findsOneWidget);
    }

    final trailingIcons = find.byIcon(Icons.arrow_forward_ios_rounded);
    final expectedTiles = PlayReleaseScope.showMagicScanQuickAction ? 4 : 3;
    expect(trailingIcons, findsAtLeastNWidgets(expectedTiles));
  });
}
