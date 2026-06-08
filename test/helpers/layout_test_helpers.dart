import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [widget] at a fixed viewport; reset with [resetTestView] in tearDown.
Future<void> pumpAtViewport(
  WidgetTester tester,
  Widget widget, {
  required Size physicalSize,
  double devicePixelRatio = 1.0,
  double textScaleFactor = 1.0,
  bool settle = false,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: widget,
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Finite animations only — flutter_animate on dashboard never settles.
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void expectNoLayoutOverflow(WidgetTester tester) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'Unexpected layout overflow or render error',
  );
}

void resetTestView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}
