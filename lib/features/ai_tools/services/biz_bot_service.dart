import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../expenses/models/expense_category.dart';
import '../../settings/providers/settings_provider.dart';
import '../../auth/providers/auth_repository.dart';
import 'package:intl/intl.dart';

class BizBotService {
  final GeminiService _gemini;
  final Ref _ref;
  static const String _conversationId = 'bizbot_main'; // Single conversation for BizBot

  BizBotService(this._gemini, this._ref);

  Future<String> ask(String question) async {
    final context = await _prepareContext();

    final systemPrompt = '''
Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov.
Máš prístup k aktuálnym finančným údajom používateľa (uvedené nižšie).
Tvojou úlohou je stručne a profesionálne odpovedať na otázky týkajúce sa jeho podnikania, daní a výdavkov v slovenčine.

AKTUÁLNY KONTEXT POUŽÍVATEĽA:
$context

PRAVIDLÁ:
1. Odpovedaj v slovenčine.
2. Buď vecný a presný.
3. Ak nepoznáš odpoveď na základe dát, priznaj to a navrhni všeobecnú radu pre slovenské prostredie.
4. Nikdy neuvádzaj fiktívne čísla, ak nie sú v kontexte.
5. Pamätaj si predchádzajúci kontext rozhovoru pre súvislé odpovede.
''';

    // Use conversation-aware generation for context continuity
    final fullPrompt = '$systemPrompt\n\nPOUŽÍVATEĽ SA PÝTA: $question';
    return await _gemini.generateWithContext(_conversationId, fullPrompt);
  }

  // Streaming version for real-time responses
  Stream<String> askStream(String question) async* {
    final context = await _prepareContext();

    final systemPrompt = '''
Si BizAgent AI - inteligentný asistent pre slovenských podnikateľov.
Máš prístup k aktuálnym finančným údajom používateľa (uvedené nižšie).
Tvojou úlohou je stručne a profesionálne odpovedať na otázky týkajúce sa jeho podnikania, daní a výdavkov v slovenčine.

AKTUÁLNY KONTEXT POUŽÍVATEĽA:
$context

PRAVIDLÁ:
1. Odpovedaj v slovenčine.
2. Buď vecný a presný.
3. Ak nepoznáš odpoveď na základe dát, priznaj to a navrhni všeobecnú radu pre slovenské prostredie.
4. Nikdy neuvádzaj fiktívne čísla, ak nie sú v kontexte.
''';

    final fullPrompt = '$systemPrompt\n\nPOUŽÍVATEĽ SA PÝTA: $question';

    String fullResponse = '';
    await for (final chunk in _gemini.generateContentStream(fullPrompt)) {
      fullResponse = chunk;
      yield chunk;
    }

    // Add to conversation memory after streaming completes
    _gemini.addToConversation(_conversationId, fullPrompt, fullResponse);
  }

  Future<String> _prepareContext() async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    final invoices = _ref.read(invoicesProvider).valueOrNull ?? [];
    final expenses = _ref.read(expensesProvider).valueOrNull ?? [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final monthInvoices = invoices.where((i) => i.dateIssued.isAfter(monthStart)).toList();
    final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart)).toList();

    final double totalInvoiced = monthInvoices.fold(0, (sum, i) => sum + i.totalAmount);
    final double totalExpenses = monthExpenses.fold(0, (sum, e) => sum + e.amount);

    final currency = NumberFormat.currency(symbol: '€', locale: 'sk_SK');

    return '''
Firma: ${settings?.companyName ?? 'Neznáma'}
IČO: ${settings?.companyIco ?? '-'}
Platca DPH: ${settings?.isVatPayer ?? false ? 'Áno' : 'Nie'}

ŠTATISTIKA ZA TENTO MESIAC (${DateFormat('MMMM yyyy', 'sk').format(now)}):
- Celkovo vyfakturované: ${currency.format(totalInvoiced)}
- Celkové výdavky: ${currency.format(totalExpenses)}
- Počet faktúr: ${monthInvoices.length}
- Počet výdavkov: ${monthExpenses.length}

POSLEDNÉ TRANSAKCIE:
${monthExpenses.take(5).map((e) => "- ${e.vendorName}: ${currency.format(e.amount)} (${e.category?.displayName})").join('\n')}
''';
  }

  // Conversation management methods
  Future<void> softDeleteConversation({String? reason}) async {
    final userId = _ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    // Move to soft delete collection
    await _ref.read(softDeleteServiceProvider).softDeleteItem(
      SoftDeleteCollections.bizBotConversations,
      userId,
      _conversationId,
      reason: reason,
    );

    // Clear current conversation memory
    GeminiService.clearConversation(_conversationId);
  }

  Future<void> restoreConversation() async {
    final userId = _ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null) return;

    await _ref.read(softDeleteServiceProvider).restoreItem(
      SoftDeleteCollections.bizBotConversations,
      userId,
      _conversationId,
    );
  }
}

final bizBotServiceProvider = Provider<BizBotService>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return BizBotService(gemini, ref);
});
