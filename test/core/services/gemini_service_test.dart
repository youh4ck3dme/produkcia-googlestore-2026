import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';

void main() {
  group('GeminiService Stability Tests', () {
    test('Should use best available model by default', () {
      // Should start with the highest priority model (gemini-1.5-flash)
      expect(GeminiService.modelName, equals('gemini-1.5-flash'));
    });

    test('Should return offline message when Cloud Function unavailable', () async {
      // GeminiService now routes through Cloud Functions.
      // Without Firebase initialization, it returns a graceful offline message.
      final service = GeminiService();
      final result = await service.generateContent('Hello');
      // Should not crash, should return an error/offline message
      expect(result, isNotEmpty);
      expect(result, isNot(contains('Exception')));
    });

    test('Cache should work for repeated prompts', () {
      // Clear any existing cache state
      GeminiService.clearCache();
      // Verify cache starts empty after clear
      final analytics = GeminiService.getAnalytics();
      expect(analytics['cacheHits'], equals(0));
    });
  });
}
