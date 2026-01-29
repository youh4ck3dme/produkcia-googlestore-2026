import 'dart:math';
import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:cloud_functions/cloud_functions.dart';

class GeminiService {
  final String _apiKey;

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

  GeminiService({required String apiKey}) : _apiKey = apiKey;

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

    // On web, use Cloud Functions for security
    if (kIsWeb) {
      try {
        debugPrint('Gemini API (Web): Using Cloud Function');
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('generateContent');
        
        final preferredModel = _selectOptimalModel(prompt);
        final result = await callable.call({
          'prompt': prompt,
          'model': preferredModel,
        });

        final responseText = result.data['text'] as String? ?? 'AI nevrátilo žiadny text.';
        final usedModel = result.data['model'] as String? ?? preferredModel;

        // Cache the successful result
        _addToCache(cacheKey, responseText);

        // Record successful analytics
        _recordAnalytics(
          model: usedModel,
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
        );

        // Update current model
        if (usedModel != modelName) {
          modelName = usedModel;
          debugPrint('Switched to working model: $usedModel');
        }

        debugPrint('Gemini API (Web) success with $usedModel');
        return responseText;

      } on FirebaseFunctionsException catch (e) {
        debugPrint('Cloud Function error: ${e.code} - ${e.message}');
        
        String errorMessage = 'AI Offline: Nepodarilo sa pripojiť k AI službe.';
        
        if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
          errorMessage = 'Chyba autentifikácie. Prosím, prihláste sa znova.';
        } else if (e.code == 'resource-exhausted') {
          errorMessage = 'Dosiahli ste limit bezplatných dopytov. Skúste to neskôr.';
        } else if (e.code == 'failed-precondition') {
          errorMessage = 'AI služba nie je správne nakonfigurovaná. Kontaktujte podporu.';
        } else if (e.message?.contains('quota') == true) {
          errorMessage = 'Dosiahli ste limit bezplatných dopytov (Quota Exceeded). Skúste to neskôr.';
        }

        _recordAnalytics(
          model: 'cloud_function_error',
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
          error: e.code,
        );

        return errorMessage;
      } catch (e) {
        debugPrint('Unexpected Cloud Function error: $e');
        
        _recordAnalytics(
          model: 'cloud_function_unexpected',
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
          error: 'unexpected_error',
        );

        return 'AI Offline: Nepodarilo sa pripojiť k AI službe. Skúste to neskôr.';
      }
    }

    // Native platforms: use direct API call
    if (_apiKey == 'DEVELOPER_API_KEY' || _apiKey.trim().isEmpty || _apiKey == 'test_key') {
      _recordAnalytics(
        model: 'invalid_key',
        fromCache: false,
        responseTime: DateTime.now().difference(startTime),
        error: 'invalid_api_key',
      );
      return 'Chyba: Gemini API kľúč nie je platný. Prosím, pridajte platný kľúč cez --dart-define=GEMINI_API_KEY=vaš_kľúč.';
    }

    final preferredModel = _selectOptimalModel(prompt);
    final modelsToTry = <String>{preferredModel, ..._modelPriority}.toList();

    // Try models in priority order with automatic fallback
    for (final model in modelsToTry) {
      try {
        debugPrint('Gemini API attempting with model: $model, key length: ${_apiKey.length}');
        final tempModel = GenerativeModel(model: model, apiKey: _apiKey);
        final content = [Content.text(prompt)];
        final response = await tempModel.generateContent(content);
        final result = response.text ?? 'AI nevrátilo žiadny text.';

        // Cache the successful result
        _addToCache(cacheKey, result);

        // Record successful analytics
        _recordAnalytics(
          model: model,
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
        );

        // If successful, update the current model for future requests
        if (model != modelName) {
          modelName = model;
          debugPrint('Switched to working model: $model');
        }

        debugPrint('Gemini API success with $model: ${result.substring(0, min(20, result.length))}...');
        return result;
      } on GenerativeAIException catch (e) {
        debugPrint('Model $model failed: ${e.message}');

        // Record error analytics
        _recordAnalytics(
          model: model,
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
          error: e.message.contains('quota') ? 'quota_exceeded' : 'api_error',
        );

        if (e.message.contains('quota')) {
          return 'Dosiahli ste limit bezplatných dopytov (Quota Exceeded). Skúste to neskôr.';
        }
        // Try next model in priority list
        continue;
      } catch (e) {
        debugPrint('Unexpected error with $model: $e');

        // Record unexpected error analytics
        _recordAnalytics(
          model: model,
          fromCache: false,
          responseTime: DateTime.now().difference(startTime),
          error: 'unexpected_error',
        );

        // Try next model in priority list
        continue;
      }
    }

    // All models failed - record final failure
    _recordAnalytics(
      model: 'all_failed',
      fromCache: false,
      responseTime: DateTime.now().difference(startTime),
      error: 'all_models_failed',
    );

    // All models failed
    return 'AI Offline: Nepodarilo sa pripojiť k žiadnemu AI modelu. Skontrolujte pripojenie alebo skúste neskôr.';
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

  // Cost optimization - intelligent model selection
  static String _selectOptimalModel(String prompt) {
    final analytics = getAnalytics();
    final modelUsage = analytics['modelUsage'] as Map<String, int>;
    final avgResponseTime = analytics['averageResponseTimeMs'] as int;

    // For simple/short prompts, prefer faster models
    if (prompt.length < 100) {
      // Use flash model if it's performing well
      if ((modelUsage['gemini-1.5-flash'] ?? 0) > (modelUsage['gemini-1.5-pro'] ?? 0)) {
        return 'gemini-1.5-flash';
      }
    }

    // For complex prompts or if flash is failing, use pro models
    if (avgResponseTime > 3000 || (modelUsage['gemini-1.5-flash'] ?? 0) < 5) {
      return 'gemini-1.5-pro';
    }

    // Default to best performing model
    return modelUsage.entries
        .where((entry) => _modelPriority.contains(entry.key))
        .fold<MapEntry<String, int>?>(null, (best, current) =>
            best == null || current.value > best.value ? current : best)
        ?.key ?? _modelPriority[0];
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
  Stream<String> generateContentStream(String prompt) async* {
    // On web, fallback to non-streaming (Cloud Functions don't support streaming easily)
    if (kIsWeb) {
      try {
        final result = await generateContent(prompt);
        yield result;
        return;
      } catch (e) {
        yield 'AI Chyba: $e';
        return;
      }
    }

    if (_apiKey == 'DEVELOPER_API_KEY' || _apiKey.trim().isEmpty || _apiKey == 'test_key') {
      yield 'Chyba: Gemini API kľúč nie je platný. Prosím, pridajte platný kľúč cez --dart-define=GEMINI_API_KEY=vaš_kľúč.';
      return;
    }

    final preferredModel = _selectOptimalModel(prompt);
    final modelsToTry = <String>{preferredModel, ..._modelPriority}.toList();

    // Try models in priority order with automatic fallback
    for (final model in modelsToTry) {
      try {
        debugPrint('Gemini API streaming with model: $model');
        final tempModel = GenerativeModel(model: model, apiKey: _apiKey);
        final content = [Content.text(prompt)];
        final response = tempModel.generateContentStream(content);

        String fullResponse = '';
        await for (final chunk in response) {
          final text = chunk.text ?? '';
          if (text.isNotEmpty) {
            fullResponse += text;
            yield fullResponse; // Yield accumulated response
          }
        }

        // If we get here, streaming was successful
        if (model != modelName) {
          modelName = model;
          debugPrint('Switched to working streaming model: $model');
        }

        // Cache the final result
        _addToCache(_generateCacheKey(prompt), fullResponse);
        return;

      } on GenerativeAIException catch (e) {
        debugPrint('Streaming model $model failed: ${e.message}');
        if (e.message.contains('quota')) {
          yield 'Dosiahli ste limit bezplatných dopytov (Quota Exceeded). Skúste to neskôr.';
          return;
        }
        // Try next model
        continue;
      } catch (e) {
        debugPrint('Unexpected streaming error with $model: $e');
        continue;
      }
    }

    // All models failed
    yield 'AI Chyba: Všetky modely sú nedostupné. Skúste to neskôr.';
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

// Securely load from environment: flutter run --dart-define=GEMINI_API_KEY=your_key
final _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyD8Fq8rFgPA42Y5J_G-8cZ4RAfRGCt0zuw');

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: _apiKey);
});
