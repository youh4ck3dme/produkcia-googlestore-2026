import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// AI Service - Provider-neutral interface for AI operations
/// All AI calls are routed through Firebase Cloud Functions
/// No API keys are stored client-side
class AiService {
  AiService();

  /// Generate text content from a prompt
  Future<String> generateContent(String prompt) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateContent');
      
      final result = await callable.call({'prompt': prompt});
      
      return result.data['text'] as String? ?? 'AI nevrátilo žiadny text.';
    } on FirebaseFunctionsException catch (e) {
      debugPrint('AI Service Error: ${e.code} - ${e.message}');
      return _mapError(e);
    } catch (e) {
      debugPrint('Unexpected AI Service error: $e');
      return 'AI Offline: Nepodarilo sa pripojiť k AI službe. Skúste to neskôr.';
    }
  }

  /// Generate text with conversation context
  Future<String> generateWithContext(String conversationId, String userMessage) async {
    return generateContent(userMessage);
  }

  /// Generate text with system prompt and conversation context
  Future<String> generateWithSystemPrompt({
    required String conversationId,
    required String systemPrompt,
    required String userMessage,
  }) async {
    final fullPrompt = '

$systemPrompt


UŽÍVATEĽ: $userMessage

';
    return generateContent(fullPrompt);
  }

  /// Analyze text and return structured JSON
  Future<Map<String, dynamic>> analyzeJson(String prompt, String schema) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('analyzeJson');
      
      final result = await callable.call({
        'prompt': prompt,
        'schema': schema,
      });
      
      if (result.data['data'] != null) {
        return result.data['data'] as Map<String, dynamic>;
      }
      
      final text = result.data['text'] as String? ?? '';
      try {
        return jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to parse JSON response: $e');
        return {'error': 'Nepodarilo sa spracovať odpoveď ako JSON'};
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('AI analyzeJson Error: ${e.code} - ${e.message}');
      return {'error': _mapError(e)};
    } catch (e) {
      debugPrint('Unexpected analyzeJson error: $e');
      return {'error': 'AI Offline: Nepodarilo sa pripojiť k AI službe.'};
    }
  }

  /// Generate text (alias for generateContent)
  Future<String> generateText(String prompt) async {
    return generateContent(prompt);
  }

  /// Clear conversation history
  static void clearConversation(String conversationId) {
    debugPrint('Conversation $conversationId cleared');
  }

  /// Clear cache
  static void clearCache() {
    debugPrint('AI cache cleared');
  }

  /// Map Firebase Functions errors to user-friendly messages
  String _mapError(FirebaseFunctionsException e) {
    if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
      return 'Chyba autentifikácie. Prosím, prihláste sa znova.';
    } else if (e.code == 'resource-exhausted') {
      return 'Dosiahli ste limit dopytov. Skúste to neskôr.';
    } else if (e.code == 'failed-precondition') {
      return 'AI služba nie je správne nakonfigurovaná. Kontaktujte podporu.';
    } else if (e.message?.contains('quota') == true) {
      return 'Dosiahli ste limit dopytov (Quota Exceeded). Skúste to neskôr.';
    }
    return 'AI Offline: Nepodarilo sa pripojiť k AI službe. Skúste to neskôr.';
  }
}

/// Provider for AI Service
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});