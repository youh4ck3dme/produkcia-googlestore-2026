import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

// Analysis result model
class VatAnalysisResult {
  final bool isTaxDeductible;
  final String? warningMessage; // e.g., "Pozor: Alkohol nie je daňový náklad"
  final String itemCategory; // e.g., "Kancelárske potreby", "Reprezentatívne"
  final double confidence; // 0.0 - 1.0

  VatAnalysisResult({
    required this.isTaxDeductible,
    this.warningMessage,
    required this.itemCategory,
    required this.confidence,
  });

  factory VatAnalysisResult.fromJson(Map<String, dynamic> json) {
    return VatAnalysisResult(
      isTaxDeductible: json['isTaxDeductible'] ?? true,
      warningMessage: json['warningMessage'],
      itemCategory: json['itemCategory'] ?? 'Všeobecné',
      confidence: (json['confidence'] ?? 1.0).toDouble(),
    );
  }
}

class AiTaxAssistantService {
  final GeminiService _gemini;

  AiTaxAssistantService(this._gemini);

  Future<VatAnalysisResult> analyzeExpenseItem(String itemName, double amount) async {
    final schema = '''
    {
      "isTaxDeductible": boolean,
      "warningMessage": string | null,
      "itemCategory": string,
      "confidence": number
    }
    ''';

    final prompt = '''
    Analyzuj výdavok pre slovenského živnostníka (SZČO).
    Položka: $itemName
    Suma: $amount €
    
    Zameraj sa na:
    1. Daňovú uznateľnosť (napr. alkohol je nedaňový, káva/jedlo je rizikové reprezentatívne).
    2. Správnu kategóriu (PHM, Hardvér, Kancelárske potreby, Služby).
    3. Ak je položka riziková, pridaj stručné vysvetlenie v slovenčine do warningMessage.
    ''';

    try {
      final response = await _gemini.analyzeJson(prompt, schema);
      final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      return VatAnalysisResult.fromJson(data);
    } catch (e) {
      // Fallback to safe guess if AI fails
      return VatAnalysisResult(
        isTaxDeductible: true,
        itemCategory: 'Nespracované',
        confidence: 0.5,
        warningMessage: 'Nepodarilo sa vykonať AI analýzu.',
      );
    }
  }

  Future<bool> validateIco(String ico) async {
    // API call to FinStat / ORSR
    final icoRegex = RegExp(r'^[0-9]{8}$');
    return icoRegex.hasMatch(ico.trim());
  }
}

final aiTaxAssistantServiceProvider = Provider<AiTaxAssistantService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return AiTaxAssistantService(gemini);
});
