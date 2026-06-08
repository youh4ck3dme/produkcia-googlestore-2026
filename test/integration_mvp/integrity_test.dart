import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/core/supabase/supabase_config.dart';
import 'package:bizagent/core/ui/biz_theme.dart';

import '../helpers/integration_harness.dart';

void main() {
  setUpAll(() async {
    await setUpIntegrationHarness();
  });

  group('Data Integrity Tests', () {
    test('Supabase configuration is readable', () {
      expect(SupabaseConfig.url, isA<String>());
      expect(SupabaseConfig.publishableKey, isA<String>());
      expect(SupabaseConfig.isConfigured, isA<bool>());
    });
  });

  group('API Integrity Tests', () {
    test('Gemini Service Model Configuration', () {
      expect(GeminiService.modelName, isNotEmpty);
      expect(
        ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash'],
        contains(GeminiService.modelName),
      );
    });

    test('IcoAtlas Service Configuration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(icoAtlasServiceProvider), isNotNull);
    });
  });

  group('Theme Integrity Tests', () {
    test('Theme Colors Consistency', () {
      expect(BizTheme.slovakBlue.toARGB32(), greaterThan(0));
      expect(BizTheme.nationalRed.toARGB32(), greaterThan(0));
      expect(BizTheme.silverMist.toARGB32(), greaterThan(0));
    });

    test('Theme Accessibility', () {
      // Statické farby — plné BizTheme.light() je v test/core/ui/biz_theme_test.dart
      expect(BizTheme.slovakBlue, isNotNull);
      expect(BizTheme.tatraWhite, isNotNull);
    });
  });

  group('Configuration Integrity Tests', () {
    test('Environment Variables', () {
      const geminiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      const icoAtlasKey = String.fromEnvironment('ICOATLAS_API_KEY', defaultValue: '');
      expect(geminiKey, isA<String>());
      expect(icoAtlasKey, isA<String>());
    });
  });
}
