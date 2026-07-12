import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/models/expense_category.dart';
import '../models/expense_insight_model.dart';
import 'package:flutter/material.dart';
import '../../../core/services/gemini_service.dart';

final expenseInsightsServiceProvider = Provider<ExpenseInsightsService>((ref) {
  return ExpenseInsightsService(ref.watch(geminiServiceProvider));
});

class ExpenseInsightsService {
  final GeminiService _gemini;

  ExpenseInsightsService(this._gemini);

  Future<List<ExpenseInsight>> analyzeExpenses(
      List<ExpenseModel> expenses) async {
    // Return empty list for empty expenses
    if (expenses.isEmpty) return [];

    final expenseData = expenses
        .map((e) => {
              'vendor': e.vendorName,
              'amount': e.amount,
              'date': e.date.toIso8601String(),
              'category': e.category?.displayName ?? 'other',
            })
        .toList();

    final prompt = '''
Analyzuj výdavky slovenského SZČO / živnostníka a navrhni praktické postrehy.
Zameraj sa na:
1. Opakujúce sa vzory výdavkov.
2. Možnosti úspory.
3. Anomálie oproti bežnému mesiacu.
4. Orientačné daňové tipy podľa kategórií (informatívne, nie záväzné poradenstvo).

Výdavky (JSON):
${jsonEncode(expenseData)}

Výstup MUSÍ byť JSON pole objektov s poliami:
- id: unikátny reťazec
- title: stručný slovenský názov
- description: slovenské vysvetlenie
- icon: jedna z [trending_up, trending_down, warning, lightbulb, savings, shopping_cart]
- color: jedna z [red, green, orange, blue, purple]
- potentialSavings: odhad mesačnej úspory v EUR (číslo alebo null)
- priority: jedna z [low, medium, high]
- category: jedna z [optimization, anomaly, trend]
- createdAt: aktuálny ISO dátum

Vráť IBA platný JSON bez markdown.
''';

    try {
      final text = await _gemini.generateContent(prompt);
      if (text.isEmpty) return [];

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
