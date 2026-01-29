import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/models/expense_category.dart';
import '../models/expense_insight_model.dart';
import 'package:flutter/material.dart';

final expenseInsightsServiceProvider = Provider<ExpenseInsightsService>((ref) {
  // Use a placeholder or environment variable for the API key
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  return ExpenseInsightsService(apiKey);
});

class ExpenseInsightsService {
  final String _apiKey;
  late final GenerativeModel _model;

  ExpenseInsightsService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<List<ExpenseInsight>> analyzeExpenses(
      List<ExpenseModel> expenses) async {
    // Return empty list for empty expenses regardless of API key
    if (expenses.isEmpty) return [];
    
    if (_apiKey.isEmpty) {
      return _getDemoInsights();
    }

    final expenseData = expenses
        .map((e) => {
              'vendor': e.vendorName,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
              'category': e.category?.displayName ?? 'other',
            })
        .toList();

    final prompt = '''
Analyze these business expenses for a Slovak SZČO (self-employed) and provide actionable insights.
Focus on identifying:
1. Reoccurring spending patterns.
2. Savings opportunities.
3. Sudden anomalies.
4. Tax optimization tips based on categories.

Expenses:
${jsonEncode(expenseData)}

Output MUST be a JSON array of objects with these fields:
- id: unique string
- title: concise Slovak title
- description: detailed Slovak explanation
- icon: one of [trending_up, trending_down, warning, lightbulb, savings, shopping_cart]
- color: one of [red, green, orange, blue, purple]
- potentialSavings: estimated monthly savings in EUR (number or null)
- priority: one of [low, medium, high]
- category: one of [optimization, anomaly, trend]
- createdAt: current ISO date
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      final List<dynamic> jsonList = jsonDecode(text);
      return jsonList
          .map((j) => ExpenseInsight.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error generating insights: $e');
      return _getDemoInsights();
    }
  }

  List<ExpenseInsight> _getDemoInsights() {
    return [
      ExpenseInsight(
        id: '1',
        title: 'Viac výdavkov na cestovné',
        description:
            'Tento mesiac ste minuli o 35% viac na pohonné hmoty než v priemere.',
        icon: Icons.trending_up,
        color: Colors.orange,
        priority: InsightPriority.medium,
        createdAt: DateTime.now(),
        category: 'trend',
      ),
      ExpenseInsight(
        id: ' savings_tax',
        title: 'Možná daňová úspora',
        description:
            'V kategórii "Kancelária" máte málo dokladov. Nezabudli ste odložiť niektoré bločky?',
        icon: Icons.lightbulb_outline,
        color: Colors.blue,
        potentialSavings: 50.0,
        priority: InsightPriority.high,
        createdAt: DateTime.now(),
        category: 'optimization',
      ),
    ];
  }
}
