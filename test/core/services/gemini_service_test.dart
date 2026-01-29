import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';

void main() {
  group('GeminiService Stability Tests', () {
    test('Should use best available model by default', () {
      // Should start with the highest priority model (gemini-1.5-flash)
      expect(GeminiService.modelName, equals('gemini-1.5-flash'));
    });

    test('Should reject empty API keys gracefully', () async {
      final service = GeminiService(apiKey: '');
      final result = await service.generateContent('Hello');
      expect(result, contains('Chyba: Gemini API kľúč nie je platný'));
    });
    
    test('Should reject developer placeholder keys', () async {
      final service = GeminiService(apiKey: 'DEVELOPER_API_KEY');
      final result = await service.generateContent('Hello');
      expect(result, contains('Chyba: Gemini API kľúč nie je platný'));
    });
  });
}
