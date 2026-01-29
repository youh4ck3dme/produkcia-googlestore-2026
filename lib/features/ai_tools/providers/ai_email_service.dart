import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';

final aiEmailServiceProvider = Provider<AiEmailService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return AiEmailService(gemini);
});

class AiEmailService {
  final GeminiService _gemini;

  AiEmailService(this._gemini);

  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    if (context.isEmpty) {
      return 'Prosím, zadajte kontext pre vygenerovanie e-mailu.';
    }

    final prompt = '''
      Vygeneruj profesionálny slovenský e-mail typu "${_getReadableType(type)}" v tóne "$tone".
      
      KONTEXT / DETAILY:
      $context
      
      E-mail musí byť v slovenčine, gramaticky správny a pripravený na odoslanie.
    ''';

    try {
      return await _gemini.generateText(prompt);
    } catch (e) {
      return 'Nepodarilo sa vygenerovať e-mail: $e';
    }
  }

  String _getReadableType(String type) {
    switch (type) {
      case 'reminder':
        return 'Upomienka k platbe';
      case 'quote':
        return 'Cenová ponuka';
      case 'intro':
        return 'Predstavenie služieb';
      default:
        return type;
    }
  }
}
