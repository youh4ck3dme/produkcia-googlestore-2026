import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bizagent/features/ai_tools/services/biz_bot_prompt.dart';
import 'package:bizagent/features/ai_tools/models/bizbot_message.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/models/expense_category.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/tax/providers/tax_estimation_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('sk');
  });

  test('systemPrompt obsahuje SK guardrails a disclaimer', () {
    final prompt = BizBotPrompt.systemPrompt();
    expect(prompt, contains('slovensk'));
    expect(prompt, contains('49790'));
    expect(prompt, contains('účtovníka'));
    expect(prompt, contains('NIE daňový poradca'));
  });

  test('formatBusinessContext obsahuje YTD, DPH limit a nezaplatené faktúry', () {
    final now = DateTime(2026, 7, 15);
    final ctx = BizBotPrompt.formatBusinessContext(
      settings: UserSettingsModel(
        companyName: 'Test s.r.o.',
        companyAddress: 'Bratislava',
        companyIco: '12345678',
        companyDic: '1234567890',
        companyIcDph: '',
        bankAccount: '',
        swift: '',
        registerInfo: 'Živnosť — IT služby',
        isVatPayer: false,
      ),
      invoices: [
        InvoiceModel(
          id: '1',
          userId: 'u1',
          createdAt: DateTime(2026, 7, 1),
          number: 'FA-001',
          clientName: 'Klient A',
          dateIssued: DateTime(2026, 7, 1),
          dateDue: DateTime(2026, 6, 1),
          status: InvoiceStatus.sent,
          items: [],
          totalAmount: 500,
        ),
      ],
      expenses: [
        ExpenseModel(
          id: 'e1',
          userId: 'u1',
          vendorName: 'Slovnaft',
          description: 'Tankovanie',
          amount: 80,
          date: DateTime(2026, 7, 10),
          category: ExpenseCategory.fuel,
        ),
      ],
      tax: TaxEstimationModel(
        ytdRevenue: 12000,
        ytdExpenses: 4000,
        estimatedIncomeTax: 1200,
        estimatedVatLiability: 0,
        vatTurnoverLtm: 45000,
        isVatPayer: false,
        netProfit: 8000,
      ),
      now: now,
    );

    expect(ctx, contains('Test s.r.o.'));
    expect(ctx, contains('Tržby YTD'));
    expect(ctx, contains('49790'));
    expect(ctx, contains('Po splatnosti'));
    expect(ctx, contains('Slovnaft'));
    expect(ctx, contains('Živnosť'));
  });

  test('formatChatHistory formátuje správy chronologicky', () {
    final history = BizBotPrompt.formatChatHistory([
      BizBotMessage(
        id: '2',
        text: 'Odpoveď bota',
        isUser: false,
        createdAt: DateTime(2026, 7, 2),
      ),
      BizBotMessage(
        id: '1',
        text: 'Otázka',
        isUser: true,
        createdAt: DateTime(2026, 7, 1),
      ),
    ]);

    expect(history, contains('Používateľ: Otázka'));
    expect(history, contains('BizBot: Odpoveď bota'));
    expect(history.indexOf('Otázka'), lessThan(history.indexOf('Odpoveď bota')));
  });

  test('buildUserPrompt rešpektuje max dĺžku', () {
    final longContext = 'x' * 12000;
    final prompt = BizBotPrompt.buildUserPrompt(
      businessContext: longContext,
      chatHistory: '',
      userMessage: 'Ahoj',
    );
    expect(prompt.length, lessThanOrEqualTo(BizBotPrompt.maxPromptChars + 200));
    expect(prompt, contains('UŽÍVATEĽSKÁ OTÁZKA: Ahoj'));
  });
}