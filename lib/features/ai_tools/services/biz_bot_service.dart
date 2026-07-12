import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../invoices/providers/invoices_provider.dart';
import '../../expenses/providers/expenses_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../auth/providers/auth_repository.dart';
import '../../tax/providers/tax_estimation_service.dart';
import '../models/bizbot_message.dart';
import '../providers/bizbot_history_provider.dart';
import 'biz_bot_prompt.dart';

class BizBotService {
  BizBotService(this._gemini, this._ref);

  final GeminiService _gemini;
  final Ref _ref;
  static const String _conversationId = 'bizbot_main';

  Future<String> ask(String question) async {
    final prompt = await _buildPrompt(question);
    final response = await _gemini.generateContent(prompt);
    _gemini.addToConversation(_conversationId, question, response);
    return response;
  }

  Stream<String> askStream(String question) async* {
    final prompt = await _buildPrompt(question);

    String fullResponse = '';
    await for (final chunk in _gemini.generateContentStream(prompt)) {
      fullResponse = chunk;
      yield chunk;
    }

    _gemini.addToConversation(_conversationId, question, fullResponse);
  }

  Future<String> _buildPrompt(String question) async {
    final settings = _ref.read(settingsProvider).value;
    final invoices = _ref.read(invoicesProvider).value ?? [];
    final expenses = _ref.read(expensesProvider).value ?? [];
    final tax = _ref.read(taxEstimationProvider).value;

    final history = await _loadRecentChatHistory();

    final businessContext = BizBotPrompt.formatBusinessContext(
      settings: settings,
      invoices: invoices,
      expenses: expenses,
      tax: tax,
      now: DateTime.now(),
    );

    final chatHistory = BizBotPrompt.formatChatHistory(history);

    return BizBotPrompt.buildUserPrompt(
      businessContext: businessContext,
      chatHistory: chatHistory,
      userMessage: question,
    );
  }

  Future<List<BizBotMessage>> _loadRecentChatHistory() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return const [];

    final repo = _ref.read(bizBotHistoryRepositoryProvider);
    final messages = await repo.fetchRecentMessages(
      user.id,
      limit: BizBotPrompt.maxHistoryMessages,
    );

    // Posledná správa môže byť práve odoslaná userom — v histórii ju necháme,
    // generateWithSystemPrompt ju neukladá duplicitne do RAM.
    return messages;
  }

  Future<void> softDeleteConversation({String? reason}) async {
    final userId = _ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    await _ref.read(softDeleteServiceProvider).softDeleteItem(
      SoftDeleteCollections.bizBotConversations,
      userId,
      _conversationId,
      reason: reason,
    );

    GeminiService.clearConversation(_conversationId);
  }

  Future<void> restoreConversation() async {
    final userId = _ref.read(authStateProvider).value?.id;
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