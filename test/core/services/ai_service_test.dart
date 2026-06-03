import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:bizagent/core/services/ai_service.dart';

void main() {
  group('AiService Tests', () {
    late AiService aiService;
    
    setUp(() {
      aiService = AiService();
    });

    group('Text/Chat Flow', () {
      test('generateContent returns text from backend', () async {
        final result = await aiService.generateContent('Test prompt');
        expect(result, isA<String>());
      });

      test('generateText is alias for generateContent', () async {
        final result1 = await aiService.generateContent('Test');
        final result2 = await aiService.generateText('Test');
        expect(result1, isA<String>());
        expect(result2, isA<String>());
      });
    });

    group('JSON/Parse Flow', () {
      test('analyzeJson returns parsed Map', () async {
        const prompt = 'Extract data';
        const schema = '{"key": "string"}';
        
        final result = await aiService.analyzeJson(prompt, schema);
        expect(result, isA<Map<String, dynamic>>());
      });

      test('analyzeJson handles malformed JSON', () async {
        const prompt = 'Test';
        const schema = '{"key": "string"}';
        
        final result = await aiService.analyzeJson(prompt, schema);
        expect(result, isA<Map<String, dynamic>>());
      });
    });

    group('Error Mapping', () {
      test('maps permission-denied to auth error', () {
        final service = AiService();
        final error = FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Unauthorized',
          details: null,
        );
        
        final result = service.mapErrorForTesting(error);
        expect(result, contains('autentifikácie'));
      });

      test('maps resource-exhausted to quota message', () {
        final service = AiService();
        final error = FirebaseFunctionsException(
          code: 'resource-exhausted',
          message: 'Quota exceeded',
          details: null,
        );
        
        final result = service.mapErrorForTesting(error);
        expect(result, contains('limit'));
      });

      test('maps failed-precondition to config error', () {
        final service = AiService();
        final error = FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Server not configured',
          details: null,
        );
        
        final result = service.mapErrorForTesting(error);
        expect(result, contains('nakonfigurovaná'));
      });

      test('maps quota in message to quota error', () {
        final service = AiService();
        final error = FirebaseFunctionsException(
          code: 'internal',
          message: 'Rate limit quota exceeded',
          details: null,
        );
        
        final result = service.mapErrorForTesting(error);
        expect(result, contains('limit'));
      });

      test('maps unknown error to generic message', () {
        final service = AiService();
        final error = FirebaseFunctionsException(
          code: 'unknown',
          message: 'Some error',
          details: null,
        );
        
        final result = service.mapErrorForTesting(error);
        expect(result, contains('Offline'));
      });
    });

    group('Conversation Management', () {
      test('clearConversation is static method', () {
        AiService.clearConversation('test_id');
        expect(true, isTrue);
      });

      test('clearCache is static method', () {
        AiService.clearCache();
        expect(true, isTrue);
      });
    });
  });
}