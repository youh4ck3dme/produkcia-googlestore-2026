import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

class ParsedExpense {
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String? merchant;
  final double confidence;

  ParsedExpense({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.merchant,
    required this.confidence,
  });

  factory ParsedExpense.fromJson(Map<String, dynamic> json) {
    return ParsedExpense(
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'Iné',
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      merchant: json['merchant'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'merchant': merchant,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'ParsedExpense(description: $description, amount: $amount€, category: $category, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}

class ExpenseParserService {
  final GeminiService _gemini;

  ExpenseParserService(this._gemini);

  Future<ParsedExpense?> parseExpenseText(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      final response = await _gemini.analyzeJson(text, '''
{
  "description": "string",
  "amount": "number",
  "category": "string",
  "date": "string",
  "merchant": "string",
  "confidence": "number"
}
''');

      final parsed = ParsedExpense.fromJson(response as Map<String, dynamic>);

      // Validate the parsed data
      if (parsed.amount <= 0 || parsed.description.isEmpty) {
        return null;
      }

      return parsed;
    } catch (e) {
      // Fallback parsing for common patterns if AI fails
      return _fallbackParse(text);
    }
  }

  ParsedExpense? _fallbackParse(String text) {
    try {
      // Simple regex patterns for Slovak expense parsing
      final amountRegex = RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:€|EUR|Sk|korun)', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(text);

      if (amountMatch == null) return null;

      final amountText = amountMatch.group(1)?.replaceAll(',', '.') ?? '0';
      final amount = double.tryParse(amountText) ?? 0.0;

      if (amount <= 0) return null;

      // Simple category detection
      String category = 'Iné';
      String description = text;

      final lowerText = text.toLowerCase();

      if (lowerText.contains('jedlo') || lowerText.contains('káva') || lowerText.contains('obed') || lowerText.contains('raňajky')) {
        category = 'Jedlo';
        description = 'Jedlo';
      } else if (lowerText.contains('benzín') || lowerText.contains('doprava') || lowerText.contains('parkovanie')) {
        category = 'Doprava';
        description = 'Doprava';
      } else if (lowerText.contains('kancelária') || lowerText.contains('papier') || lowerText.contains('pero')) {
        category = 'Kancelária';
        description = 'Kancelárske potreby';
      } else if (lowerText.contains('reklam') || lowerText.contains('marketing')) {
        category = 'Marketing';
        description = 'Marketing';
      }

      // Extract merchant if present
      String? merchant;
      final merchantPatterns = [
        RegExp(r'(?:v |vo |firme |obchode |u )\s*([A-Z][a-zA-Z\s]+)', caseSensitive: false),
        RegExp(r'"([^"]+)"'),
      ];

      for (final pattern in merchantPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          merchant = match.group(1)?.trim();
          break;
        }
      }

      return ParsedExpense(
        description: description,
        amount: amount,
        category: category,
        date: DateTime.now(),
        merchant: merchant,
        confidence: 0.7, // Lower confidence for fallback parsing
      );
    } catch (e) {
      return null;
    }
  }

  /// Get suggested categories for Slovak businesses
  static const List<String> suggestedCategories = [
    'Jedlo',
    'Doprava',
    'Kancelária',
    'Marketing',
    'Služby',
    'Materiál',
    'Elektronika',
    'Oblečenie',
    'Zdravie',
    'Vzdelávanie',
    'Iné',
  ];

  /// Validate if parsed expense looks reasonable
  bool isValidExpense(ParsedExpense expense) {
    return expense.amount > 0 &&
           expense.amount < 100000 && // Reasonable upper limit
           expense.description.isNotEmpty &&
           expense.confidence > 0.3; // Minimum confidence threshold
  }
}

// Provider for the expense parser service
final expenseParserServiceProvider = Provider<ExpenseParserService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ExpenseParserService(geminiService);
});
