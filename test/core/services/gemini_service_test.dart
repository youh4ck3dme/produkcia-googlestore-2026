import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bizagent/core/services/gemini_service.dart';

import '../../helpers/fake_supabase_functions_client.dart';

void main() {
  group('GeminiService', () {
    late FakeSupabaseFunctionsClient functions;

    setUp(() {
      GeminiService.clearCache();
      functions = FakeSupabaseFunctionsClient();
    });

    test('returns offline message when Supabase functions unavailable', () async {
      functions.isReady = false;
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Ahoj');

      expect(result, 'AI Offline: služba nie je nakonfigurovaná.');
    });

    test('returns text from generate-content edge function', () async {
      functions.responseData = {
        'text': 'Odpoveď z Mistral',
        'model': 'mistral-small-latest',
        'provider': 'mistral',
      };
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Ahoj');

      expect(result, 'Odpoveď z Mistral');
      expect(functions.lastFunctionName, 'generate-content');
      expect(functions.lastBody?['prompt'], 'Ahoj');
    });

    test('uses cache on repeated identical prompt', () async {
      functions.responseData = {'text': 'Cached answer', 'model': 'mistral-small-latest'};
      final service = GeminiService(functionsClient: functions);

      await service.generateContent('Same prompt');
      await service.generateContent('Same prompt');

      expect(functions.invokeCount, 1);
    });

    test('maps 401 FunctionException to auth error message', () async {
      functions.statusCode = 401;
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Test');

      expect(result, contains('autentifikácie'));
    });

    test('maps 429 FunctionException to rate limit message', () async {
      functions.statusCode = 429;
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Test');

      expect(result, contains('limit'));
    });

    test('maps 503 FunctionException to temporary unavailable message', () async {
      functions.statusCode = 503;
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Test');

      expect(result, contains('dočasne nedostupné'));
    });

    test('falls back when response has no text field', () async {
      functions.responseData = {'model': 'mistral-small-latest'};
      final service = GeminiService(functionsClient: functions);

      final result = await service.generateContent('Test');

      expect(result, 'AI nevrátilo žiadny text.');
    });
  });
}
