import 'dart:math';
import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';

// REMOVED: hardcoded key eliminated for security
// AI volania idú cez Supabase Edge Function `generate-content` — žiadny kľúč v klientovi.

class GeminiService {
  // Multi-model strategy with automatic fallback
  // Updated to use currently supported models (January 2026)
  static const List<String> _modelPriority = [
    'gemini-1.5-flash',     // Primary - cost effective & fast, widely available
    'gemini-1.5-pro',       // Fallback - high quality precision
    'gemini-2.0-flash',     // Fallback - newer model (if available)
  ];

  static String modelName = _modelPriority[0]; // Start with best model

  // Simple in-memory cache for frequent queries (LRU with max 100 entries)
  static final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();
  static const int _maxCacheSize = 100;

  GeminiService();

  Future<String> generateContent(String prompt) async {
    final startTime = DateTime.now();

    // Check cache first for exact matches
    final cacheKey = _generateCacheKey(prompt);
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Cache hit for prompt: ${prompt.substring(0, min(30, prompt.length))}...');
      // Move to end (most recently used)
      final cached = _cache.remove(cacheKey);
      _cache[cacheKey] = cached!;

      // Record cache hit analytics
      _recordAnalytics(
        model: 'cache',
        fromCache: true,
        responseTime: DateTime.now().difference(startTime),
      );

      return cached;
    }

    // AI cez Supabase Edge Function `generate-content` (Mistral primary + Gemini fallback).
    if (!SupabaseConfig.isConfigured) {
      return 'AI Offline: služba nie je nakonfigurovaná.';
    }

    try {
      debugPrint('AI: volám Supabase Edge Function generate-content');
      final res = await SupabaseConfig.client.functions.invoke(
        'generate-content',
        body: {'prompt': prompt},
      );

      final data = res.data;
      final responseText = (data is Map ? data['text'] as String? : null) ??
          'AI nevrátilo žiadny text.';
      final usedModel =
          (data is Map ? data['model'] as String? : null) ?? modelName;

      _addToCache(cacheKey, responseText);

      _recordAnalytics(
        model: usedModel,
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
      );

      if (usedModel != modelName) {
        modelName = usedModel;
        debugPrint('Switched to working model: $usedModel');
      }

      debugPrint('AI success with $usedModel');
      return responseText;
    } on FunctionException catch (e) {
      debugPrint('Edge Function error: ${e.status} - ${e.details}');

      String errorMessage = 'AI Offline: Nepodarilo sa pripojiť k AI službe.';
      if (e.status == 401 || e.status == 403) {
        errorMessage = 'Chyba autentifikácie. Prosím, prihláste sa znova.';
      } else if (e.status == 429) {
        errorMessage = 'Dosiahli ste limit bezplatných dopytov. Skúste to neskôr.';
      } else if (e.status == 503) {
        errorMessage = 'AI dočasne nedostupné. Skúste to o chvíľu znova.';
      }

      _recordAnalytics(
        model: 'edge_function_error',
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
        error: e.status.toString(),
      );

      return errorMessage;
    } catch (e) {
      debugPrint('Unexpected Edge Function error: $e');

      _recordAnalytics(
        model: 'edge_function_unexpected',
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
        error: 'unexpected_error',
      );

      return 'AI Offline: Nepodarilo sa pripojiť k AI službe. Skúste to neskôr.';
    }
  }

  String _generateCacheKey(String prompt) {
    // Simple hash for cache key - in production, use proper hashing
    return prompt.hashCode.toString();
  }

  void _addToCache(String key, String value) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest (least recently used)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  // Clear cache if needed
  static void clearCache() {
    _cache.clear();
    debugPrint('Gemini cache cleared');
  }

  // Conversation memory for context-aware responses
  static final Map<String, List<Map<String, String>>> _conversations = {};
  static const int _maxConversationHistory = 10;

  // Add message to conversation history
  void addToConversation(String conversationId, String userMessage, String aiResponse) {
    _conversations.putIfAbsent(conversationId, () => []);
    final history = _conversations[conversationId]!;

    // Add new messages
    history.add({'role': 'user', 'content': userMessage});
    history.add({'role': 'assistant', 'content': aiResponse});

    // Keep only recent messages
    if (history.length > _maxConversationHistory * 2) {
      history.removeRange(0, history.length - _maxConversationHistory * 2);
    }
  }

  // Generate response with conversation context
  Future<String> generateWithContext(String conversationId, String userMessage) async {
    final history = _conversations[conversationId] ?? [];

    // Build context from conversation history
    final contextPrompt = history.isEmpty ? '' : '''
Predchádzajúci kontext rozhovoru:
${history.map((msg) => '${msg['role'] == 'user' ? 'Užívateľ' : 'AI'}: ${msg['content']}').join('\n')}

''';

    final fullPrompt = '${contextPrompt}Aktuálna otázka: $userMessage';

    final response = await generateContent(fullPrompt);

    // Store in conversation memory
    addToConversation(conversationId, userMessage, response);

    return response;
  }

  // Generate with system prompt + conversation memory, without storing the system prompt in memory.
  Future<String> generateWithSystemPrompt({
    required String conversationId,
    required String systemPrompt,
    required String userMessage,
  }) async {
    final history = _conversations[conversationId] ?? [];

    final historyBlock = history.isEmpty
        ? ''
        : '''
KONTEXT ROZHOVORU:
${history.map((msg) => '${msg['role'] == 'user' ? 'Užívateľ' : 'AI'}: ${msg['content']}').join('\n')}

''';

    final fullPrompt = '''
$systemPrompt

$historyBlock
UŽÍVATEĽ: $userMessage
''';

    final response = await generateContent(fullPrompt);
    addToConversation(conversationId, userMessage, response);
    return response;
  }

  // Clear conversation history
  static void clearConversation(String conversationId) {
    _conversations.remove(conversationId);
    debugPrint('Conversation $conversationId cleared');
  }

  // Analytics and monitoring
  static final Map<String, dynamic> _analytics = {
    'totalRequests': 0,
    'cacheHits': 0,
    'modelUsage': <String, int>{},
    'responseTimes': <int>[],
    'errors': <String, int>{},
    'lastReset': DateTime.now(),
  };

  // Record analytics for monitoring
  void _recordAnalytics({
    required String model,
    required bool fromCache,
    required Duration responseTime,
    String? error,
  }) {
    _analytics['totalRequests'] = (_analytics['totalRequests'] as int) + 1;

    if (fromCache) {
      _analytics['cacheHits'] = (_analytics['cacheHits'] as int) + 1;
    }

    // Track model usage
    final modelUsage = _analytics['modelUsage'] as Map<String, int>;
    modelUsage[model] = (modelUsage[model] ?? 0) + 1;

    // Track response times
    final responseTimes = _analytics['responseTimes'] as List<int>;
    responseTimes.add(responseTime.inMilliseconds);
    if (responseTimes.length > 1000) {
      responseTimes.removeAt(0); // Keep only last 1000 measurements
    }

    if (error != null) {
      final errors = _analytics['errors'] as Map<String, int>;
      errors[error] = (errors[error] ?? 0) + 1;
    }
  }

  // Get analytics data
  static Map<String, dynamic> getAnalytics() {
    final responseTimes = _analytics['responseTimes'] as List<int>;
    final avgResponseTime = responseTimes.isEmpty
        ? 0
        : responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length;

    return {
      ..._analytics,
      'averageResponseTimeMs': avgResponseTime,
      'cacheHitRate': _analytics['totalRequests'] > 0
          ? (_analytics['cacheHits'] as int) / (_analytics['totalRequests'] as int)
          : 0.0,
      'errorRate': _analytics['totalRequests'] > 0
          ? (_analytics['errors'] as Map<String, int>).values.fold(0, (sum, count) => sum + count) /
              (_analytics['totalRequests'] as int)
          : 0.0,
    };
  }

  // Reset analytics
  static void resetAnalytics() {
    _analytics.clear();
    _analytics.addAll({
      'totalRequests': 0,
      'cacheHits': 0,
      'modelUsage': <String, int>{},
      'responseTimes': <int>[],
      'errors': <String, int>{},
      'lastReset': DateTime.now(),
    });
    debugPrint('Analytics reset');
  }



  // A/B Testing framework for prompt optimization
  static final Map<String, Map<String, dynamic>> _promptTests = {};

  // Test different prompt variations
  Future<String> testPromptVariations(String basePrompt, List<String> variations) async {
    final results = <String, Map<String, dynamic>>{};

    for (final variation in variations) {
      final startTime = DateTime.now();
      final response = await generateContent(variation);
      final responseTime = DateTime.now().difference(startTime);

      results[variation] = {
        'response': response,
        'responseTime': responseTime.inMilliseconds,
        'length': response.length,
      };
    }

    // Store test results
    _promptTests[basePrompt] = {
      'timestamp': DateTime.now(),
      'variations': results,
      'bestVariation': _selectBestVariation(results),
    };

    return _selectBestVariation(results);
  }

  String _selectBestVariation(Map<String, Map<String, dynamic>> results) {
    // Select variation with best balance of speed and quality
    return results.entries
        .map((entry) => MapEntry(entry.key, _scoreVariation(entry.value)))
        .reduce((best, current) => current.value > best.value ? current : best)
        .key;
  }

  double _scoreVariation(Map<String, dynamic> result) {
    final responseTime = result['responseTime'] as int;
    final length = result['length'] as int;

    // Score: favor longer responses with reasonable speed
    // Length bonus - quality responses are typically longer
    final lengthScore = min(length / 500.0, 2.0); // Max 2 points for length

    // Speed penalty - prefer faster responses
    final speedScore = max(0, 2.0 - (responseTime / 2000.0)); // Max 2 points for speed

    return lengthScore + speedScore;
  }

  // Get A/B test results
  static Map<String, Map<String, dynamic>> getPromptTestResults() {
    return Map.from(_promptTests);
  }

  // Function calling framework for external integrations
  static final Map<String, Function> _functionRegistry = {};

  // Register external functions
  static void registerFunction(String name, Function function) {
    _functionRegistry[name] = function;
  }

  // Execute function calls from AI responses
  Future<String> executeFunction(String functionName, Map<String, dynamic> parameters) async {
    if (!_functionRegistry.containsKey(functionName)) {
      return 'Funkcia $functionName nie je dostupná.';
    }

    try {
      final function = _functionRegistry[functionName]!;
      final result = await Function.apply(function, [], parameters.map((k, v) => MapEntry(Symbol(k), v)));
      return result.toString();
    } catch (e) {
      return 'Chyba pri vykonaní funkcie $functionName: $e';
    }
  }

  // Proactive suggestions based on user data
  Future<List<String>> generateProactiveSuggestions(Map<String, dynamic> userContext) async {
    final prompt = '''
Na základe nasledujúcich údajov používateľa navrhni 3-5 užitočných akcií alebo tipov pre jeho biznis.
Buď konkrétny a praktický. Zameraj sa na slovenské prostredie a aktuálne trendy.

ÚDAJE POUŽÍVATEĽA:
${userContext.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

VRÁŤ ODPOVEĎ V SLOVENČINE ako číslovaný zoznam bez ďalších komentárov.
''';

    final response = await generateContent(prompt);
    final suggestions = response.split('\n')
        .where((line) => line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line.trim()))
        .map((line) => line.trim().substring(line.trim().indexOf('.') + 1).trim())
        .toList();

    return suggestions.take(5).toList(); // Max 5 suggestions
  }

  // Business intelligence insights
  Future<Map<String, dynamic>> analyzeBusinessTrends(List<Map<String, dynamic>> businessData) async {
    final dataSummary = businessData.map((data) =>
        data.entries.map((e) => '${e.key}: ${e.value}').join(', ')
    ).join('\n');

    final response = await analyzeJson(dataSummary, '''
{
  "trends": ["string"],
  "recommendations": ["string"],
  "risks": ["string"],
  "opportunities": ["string"],
  "confidence": "number"
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'trends': ['Analýza nie je dostupná'],
        'recommendations': ['Skúste to neskôr'],
        'risks': [],
        'opportunities': [],
        'confidence': 0.0,
      };
    }
  }

  // Tax optimization suggestions
  Future<List<String>> getTaxOptimizationTips(String businessType, double annualRevenue) async {
    final prompt = '''
Pre podnikanie typu "$businessType" s ročným obratom ${annualRevenue.toStringAsFixed(0)}€ navrhni konkrétne tipy na optimalizáciu daní v slovenskom prostredí.

Zameraj sa na:
- Legálne daňové odpočty
- Optimalizáciu DPH
- Výhodné formy podnikania
- Investičné stimuly

VRÁŤ 5-7 KONKRÉTNYCH TIPOV V SLOVENČINE ako číslovaný zoznam.
''';

    final response = await generateContent(prompt);
    final tips = response.split('\n')
        .where((line) => line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line.trim()))
        .map((line) => line.trim().substring(line.trim().indexOf('.') + 1).trim())
        .toList();

    return tips.take(7).toList();
  }

  // Advanced Multi-Modal Support
  Future<String> analyzeReceiptImage(String imagePath, {String? context}) async {
    // Note: In production, this would use Google AI Vision API + Gemini
    // For now, simulate with text-based analysis
    final prompt = '''
Analyzuj nasledujúci text z účtenky/obrázka a poskytni štruktúrovanú analýzu:

${context ?? 'ÚČTENKA DATA - simulované dáta'}

POSKYŤ ANALÝZU V TOMTO FORMÁTE:
- **Obchod:** [názov obchodu]
- **Suma:** [celková suma]€
- **DPH:** [odhad DPH]
- **Kategória:** [kategória výdavku]
- **Odporúčania:** [daňové tipy alebo úspory]
''';

    return await generateContent(prompt);
  }

  // ICO Lookup Integration (Slovak Business Registry)
  Future<Map<String, dynamic>> lookupCompanyByICO(String ico) async {
    // In production, integrate with Slovak Business Registry API
    // For now, simulate ICO validation and lookup
    final response = await analyzeJson(ico, '''
{
  "valid": "boolean",
  "companyName": "string",
  "address": "string",
  "legalForm": "string",
  "vatPayer": "boolean",
  "registrationDate": "string",
  "status": "string"
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'valid': false,
        'companyName': 'Neplatné IČO alebo chyba vyhľadávania',
        'address': '',
        'legalForm': '',
        'vatPayer': false,
        'registrationDate': '',
        'status': 'neznámy',
      };
    }
  }

  // Bank Transaction Analysis & Categorization
  Future<Map<String, dynamic>> analyzeBankTransaction(String transactionText) async {
    final response = await analyzeJson(transactionText, '''
{
  "category": "string",
  "subcategory": "string",
  "vendor": "string",
  "confidence": "number",
  "taxDeductible": "boolean",
  "suggestions": ["string"]
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'category': 'Ostatné',
        'subcategory': 'Nezaradené',
        'vendor': 'Neznámy',
        'confidence': 0.0,
        'taxDeductible': false,
        'suggestions': ['Skontrolujte ručne'],
      };
    }
  }

  // Predictive Cash Flow Analysis
  Future<Map<String, dynamic>> predictCashFlow(List<Map<String, dynamic>> historicalData) async {
    final dataSummary = historicalData.map((data) =>
        'Mesiac: ${data['month']}, Príjmy: ${data['income']}€, Výdavky: ${data['expenses']}€, Cashflow: ${data['cashflow']}€'
    ).join('\n');

    final response = await analyzeJson(dataSummary, '''
{
  "nextMonthPrediction": {"income": "number", "expenses": "number", "cashflow": "number", "confidence": "number"},
  "month2Prediction": {"income": "number", "expenses": "number", "cashflow": "number", "confidence": "number"},
  "month3Prediction": {"income": "number", "expenses": "number", "cashflow": "number", "confidence": "number"},
  "trends": ["string"],
  "recommendations": ["string"],
  "risks": ["string"]
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'nextMonthPrediction': {'income': 0, 'expenses': 0, 'cashflow': 0, 'confidence': 0.0},
        'trends': ['Predikcia nie je dostupná'],
        'recommendations': ['Skontrolujte historické dáta'],
        'risks': ['Nedostatok dát pre predikciu'],
      };
    }
  }

  // Automated Invoice Generation Assistant
  Future<Map<String, dynamic>> generateInvoiceDraft(Map<String, dynamic> invoiceData) async {
    final dataText = invoiceData.entries.map((e) => '${e.key}: ${e.value}').join(', ');

    final response = await analyzeJson(dataText, '''
{
  "invoiceNumber": "string",
  "clientName": "string",
  "clientICO": "string",
  "items": [{"description": "string", "quantity": "number", "price": "number", "vatRate": "number"}],
  "totalWithoutVAT": "number",
  "totalVAT": "number",
  "totalWithVAT": "number",
  "dueDate": "string",
  "paymentTerms": "string",
  "validationErrors": ["string"]
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'invoiceNumber': 'FA-ERROR',
        'validationErrors': ['Chyba pri generovaní faktúry'],
        'items': [],
        'totalWithoutVAT': 0,
        'totalVAT': 0,
        'totalWithVAT': 0,
      };
    }
  }

  // Compliance & Legal Check
  Future<Map<String, dynamic>> checkBusinessCompliance(String businessType, List<String> activities) async {
    final activitiesText = activities.join(', ');

    final response = await analyzeJson('$businessType: $activitiesText', '''
{
  "compliant": "boolean",
  "requiredLicenses": ["string"],
  "regulatoryRequirements": ["string"],
  "risks": ["string"],
  "recommendations": ["string"],
  "nextSteps": ["string"]
}
''');

    try {
      return Map<String, dynamic>.from(jsonDecode(response));
    } catch (e) {
      return {
        'compliant': false,
        'requiredLicenses': ['Vyžaduje sa právna konzultácia'],
        'risks': ['Nedostatok informácií pre overenie súladu'],
        'recommendations': ['Kontaktujte právnika alebo príslušný úrad'],
      };
    }
  }

  // Streaming response for real-time UI updates
  // Routes through Cloud Functions (yields final result since CF doesn't support streaming)
  Stream<String> generateContentStream(String prompt) async* {
    try {
      final result = await generateContent(prompt);
      yield result;
    } catch (e) {
      yield 'AI Chyba: $e';
    }
  }

  // Alias for backward compatibility if needed
  Future<String> generateText(String prompt) => generateContent(prompt);

  Future<String> analyzeJson(String context, String schema) async {
    final prompt = '''
Si expert na slovenské účtovníctvo a biznis asistenciu.
Spracuj nasledujúci kontext a vráť výsledok ako PURE JSON (bez markdown blokov) podľa schémy: $schema

KONTEXT:
$context
''';

    return generateContent(prompt);
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
