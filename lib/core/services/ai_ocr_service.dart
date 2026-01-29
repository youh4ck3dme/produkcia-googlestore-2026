import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_service.dart';
import 'gemini_service.dart';

final aiOcrServiceProvider = Provider<AiOcrService>((ref) {
  return AiOcrService(ref.watch(geminiServiceProvider));
});

class AiOcrService {
  final GeminiService _gemini;
  AiOcrService(this._gemini);

  Future<ParsedReceipt?> refineWithAi(String rawText,
      {String? imagePath}) async {
    try {
      const schema = '''
      {
        "suma": "double (celková suma na doklade)",
        "datum": "YYYY-MM-DD",
        "ico": "slovenský IČO kód predajcu"
      }
      ''';

      final jsonString = await _gemini.analyzeJson(rawText, schema);
      
      // Clean the response (sometimes AI adds markdown blocks even if asked for PURE JSON)
      final cleaned = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      return ParsedReceipt(
        totalAmount: data['suma']?.toString(),
        date: data['datum']?.toString(),
        vendorId: data['ico']?.toString(),
        originalText: rawText,
        imagePath: imagePath,
      );
    } catch (e) {
      debugPrint('AI OCR Error: $e');
      return null;
    }
  }
}
