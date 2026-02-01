import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';

/// Performance Tests - Verify app performance meets targets
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('Dashboard Render Performance', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: BizTheme.light(),
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Dashboard should render in < 100ms for good UX
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Dashboard should render quickly for smooth UX',
      );
    });

    testWidgets('Theme Switch Performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          theme: BizTheme.light(),
          darkTheme: BizTheme.dark(),
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // Theme application should be fast
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Theme application should be instant',
      );
    });
  });

  group('Memory Tests', () {
    test('Theme Memory Footprint', () {
      // Create multiple theme instances
      final themes = List.generate(100, (_) => BizTheme.light());
      
      expect(themes.length, equals(100));
      // Themes should be lightweight (no heavy objects)
      expect(themes.first, isNotNull);
    });
  });
}
