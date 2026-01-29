import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

enum ReminderTone {
  polite,      // "Mäkký" - for good clients
  professional, // "Profesionálny" - standard
  strict,       // "Prísny" - for late payers
}

class AiReminderService {
  final GeminiService _gemini;

  AiReminderService(this._gemini);

  Future<String> generateReminderText({
    required String clientName,
    required String invoiceNumber,
    required double amount,
    required int daysOverdue,
    required ReminderTone tone,
  }) async {
    final prompt = '''
      Vygeneruj krátku a údernú slovenskú upomienku k platbe faktúry.
      Klient: $clientName
      Číslo faktúry: $invoiceNumber
      Suma: $amount €
      Dni po splatnosti: $daysOverdue
      Tón: ${tone.name} (polite=priateľský, professional=vecný, strict=dôrazný/predžalobný)
      
      Výsledok musí byť v slovenčine, bez zbytočných omáčok, pripravený na skopírovanie do SMS alebo e-mailu.
    ''';

    try {
      return await _gemini.generateText(prompt);
    } catch (e) {
      return 'Chyba pri generovaní upomienky: $e';
    }
  }
}

final aiReminderServiceProvider = Provider<AiReminderService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return AiReminderService(gemini);
});
