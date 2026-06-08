import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bizagent/core/ui/biz_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BizTheme Compliance', () {
    testWidgets('Light theme should use Slovak Flag colors', (tester) async {
      final theme = BizTheme.light();
      final scheme = theme.colorScheme;

      // Primary Blue
      expect(scheme.primary, const Color(0xFF0B4EA2), reason: 'Primary color must optionally match Slovak Blue');
      // Primary Red
      expect(scheme.secondary, const Color(0xFFEE1C25), reason: 'Secondary color must match Slovak Red');
      // Surface
      expect(scheme.surface, const Color(0xFFFFFFFF), reason: 'Surface must be pure white');
    });

    testWidgets('Dark theme should use accessible variants', (tester) async {
      final theme = BizTheme.dark();
      final scheme = theme.colorScheme;

      // Checking high contrast variants
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary.toARGB32(), isNot(0xFF0B4EA2), reason: 'Dark primary should be lighter than slovak blue');
      expect(scheme.surface, const Color(0xFF121212));
    });

    testWidgets('Theme should enable Material 3', (tester) async {
      final theme = BizTheme.light();
      expect(theme.useMaterial3, true);
    });

    testWidgets('Buttons should have correct border radius', (tester) async {
      final theme = BizTheme.light();
      final buttonStyle = theme.elevatedButtonTheme.style;
      
      final shape = buttonStyle?.shape?.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
      
      final rounded = shape as RoundedRectangleBorder;
      final borderRadius = rounded.borderRadius as BorderRadius;
      
      expect(borderRadius.topLeft.x, BizTheme.radiusMd, reason: 'Buttons should use radiusMd (8.0)');
    });

    test('Input decoration uses visible borders and premium radius', () {
      final inputTheme = BizTheme.light().inputDecorationTheme;

      final enabled = inputTheme.enabledBorder as OutlineInputBorder?;
      final focused = inputTheme.focusedBorder as OutlineInputBorder?;

      expect(enabled?.borderSide.color, BizTheme.gray200);
      expect(enabled?.borderSide.width, 1);
      expect(focused?.borderSide.color, BizTheme.slovakBlue);
      expect(focused?.borderSide.width, 2);
      expect(
        enabled?.borderRadius,
        BorderRadius.circular(BizTheme.inputRadius),
      );
      expect(inputTheme.fillColor, BizTheme.tatraWhite);
    });

    test('formSectionDecoration matches premium card styling', () {
      final light = BizTheme.formSectionDecoration(isDark: false);
      final dark = BizTheme.formSectionDecoration(isDark: true);

      expect(light.color, BizTheme.tatraWhite);
      expect(light.border, isNotNull);
      expect(dark.color, BizTheme.darkSurfaceVariant);
      expect(light.boxShadow, isNotEmpty);
    });

    test('Card theme uses bordered sections without elevation', () {
      final cardTheme = BizTheme.light().cardTheme;

      expect(cardTheme.elevation, 0);
      expect(cardTheme.margin, EdgeInsets.zero);
      final shape = cardTheme.shape as RoundedRectangleBorder?;
      expect(shape?.side.color, BizTheme.gray200);
      expect(shape?.borderRadius, BorderRadius.circular(BizTheme.radiusLg));
    });
  });
}
