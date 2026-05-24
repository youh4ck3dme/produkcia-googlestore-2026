import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bizagent/core/services/gemini_service.dart';
import 'package:bizagent/features/ai_tools/services/ai_tax_assistant_service.dart';
import 'package:bizagent/features/ai_tools/services/ai_reminder_service.dart';
import 'package:bizagent/features/ai_tools/services/biz_bot_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI tools smoke (offline-safe)', () {
    setUpAll(() async {
      // BizBotService formats month names in sk locale.
      await initializeDateFormatting('sk');
    });

    test('BizBot returns a non-empty response even with invalid key', () async {
      final container = ProviderContainer(
        overrides: [
          geminiServiceProvider.overrideWithValue(GeminiService()),
        ],
      );
      addTearDown(container.dispose);

      final svc = container.read(bizBotServiceProvider);
      final resp = await svc.ask('Ako mám nastaviť fakturáciu?');
      expect(resp.trim(), isNotEmpty);
    });

    test('VAT assistant returns fallback on invalid key', () async {
      final container = ProviderContainer(
        overrides: [
          geminiServiceProvider.overrideWithValue(GeminiService()),
        ],
      );
      addTearDown(container.dispose);

      final svc = container.read(aiTaxAssistantServiceProvider);
      final result = await svc.analyzeExpenseItem('káva', 12.50);
      expect(result.warningMessage, isNotNull);
      expect(result.itemCategory, isNotEmpty);
    });

    test('Reminder generator returns non-empty text on invalid key', () async {
      final container = ProviderContainer(
        overrides: [
          geminiServiceProvider.overrideWithValue(GeminiService()),
        ],
      );
      addTearDown(container.dispose);

      final svc = container.read(aiReminderServiceProvider);
      final text = await svc.generateReminderText(
        clientName: 'ABC s.r.o.',
        invoiceNumber: '2026/001',
        amount: 199.0,
        daysOverdue: 7,
        tone: ReminderTone.professional,
      );
      expect(text.trim(), isNotEmpty);
    });
  });
}

