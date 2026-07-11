import 'package:bizagent/core/i18n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStringsSK', () {
    test('every AppStr has a non-empty Slovak translation', () {
      for (final key in AppStr.values) {
        final value = AppStringsSK.values[key];
        expect(value, isNotNull, reason: 'Missing translation for $key');
        expect(value!.trim(), isNotEmpty, reason: 'Empty translation for $key');
      }
    });

    test('param placeholders in templates are balanced', () {
      final paramPattern = RegExp(r'\{[a-zA-Z]+\}');
      for (final entry in AppStringsSK.values.entries) {
        final matches = paramPattern.allMatches(entry.value).length;
        if (matches == 0) continue;
        expect(matches, greaterThan(0),
            reason: 'Template ${entry.key} should use {param} syntax');
      }
    });
  });
}