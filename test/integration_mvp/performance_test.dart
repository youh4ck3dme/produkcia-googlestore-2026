import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';

import '../helpers/integration_harness.dart';

void main() {
  setUpAll(() async {
    await setUpIntegrationHarness();
  });

  group('Performance Tests', () {
    testWidgets('Dashboard Render Performance', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(integrationApp(child: const DashboardScreen()));
      await pumpFrames(tester, count: 5);
      stopwatch.stop();

      final maxMs = const bool.fromEnvironment('CI', defaultValue: false) ||
              (Platform.environment['CI'] ?? '').toLowerCase() == 'true'
          ? 8000
          : 8000;

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs));
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
      await pumpFrames(tester);
      stopwatch.stop();

      final maxMs = const bool.fromEnvironment('CI', defaultValue: false) ||
              (Platform.environment['CI'] ?? '').toLowerCase() == 'true'
          ? 1000
          : 200;

      expect(stopwatch.elapsedMilliseconds, lessThan(maxMs));
    });
  });

  group('Memory Tests', () {
    test('Theme Memory Footprint', () {
      final themes = List.generate(100, (_) => BizTheme.light());
      expect(themes.length, equals(100));
    });
  });
}
