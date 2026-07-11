import 'package:intl/intl.dart';

import '../../../core/services/tax_calculation_service.dart';
import '../../invoices/models/invoice_model.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/models/expense_category.dart';
import '../../settings/models/user_settings_model.dart';
import '../../tax/providers/tax_estimation_service.dart';
import '../models/bizbot_message.dart';

/// Referenčné hodnoty pre SK podnikateľský kontext (informatívne, nie právne záväzné).
class SlovakBusinessReference {
  SlovakBusinessReference._();

  /// Povinná registrácia platcu DPH — obrat za 12 po sebe nasledujúcich mesiacov (EUR).
  static const double vatRegistrationTurnoverEur =
      TaxCalculationService.vatRegistrationThresholdEur;

  static const double microTaxpayerIncomeLimitEur =
      TaxCalculationService.microTaxpayerIncomeLimitEur;

  static const String disclaimer =
      'Odpovede sú iba informatívne a nenahrádzajú účtovné, daňové ani právne poradenstvo. '
      'Pre záväzné rozhodnutia konzultuj účtovníka alebo daňového poradcu.';
}

/// Prompty a kontext pre BizBot — SZČO / malé firmy na Slovensku.
class BizBotPrompt {
  BizBotPrompt._();

  static const int maxHistoryMessages = 8;
  static const int maxPromptChars = 9500;

  static String systemPrompt() => '''
Si BizAgent BizBot — informačný asistent pre slovenských podnikateľov (SZČO, živnostníci, malé firmy).
Pomáhaš s fakturáciou, výdavkami, DPH, cashflowom a bežnými otázkami podnikania v SR.

GUARDRAILS (POVINNÉ):
1. Odpovedaj výhradne v slovenčine, stručne a vecne.
2. Si INFORMAČNÝ asistent — NIE daňový poradca, účtovník ani právnik.
3. Nikdy neuvádzaj záväzné sumy na podanie priznania, konkrétne termíny úradov ani „určite uplatnite X €".
4. Pri daňových/trestnoprávnych témach vždy upozorni: ${SlovakBusinessReference.disclaimer}
5. Čísla a sumy uvádzaj LEN z kontextu používateľa — inak povedz, že ich nemáš.
6. Ak chýbajú údaje (typ podnikania, paušál/skutočné náklady), explicitne sa opýtaj.
7. Pri DPH spomeň limit obratu ${SlovakBusinessReference.vatRegistrationTurnoverEur.toStringAsFixed(0)} € / 12 mes. len ako orientačný referenčný rámec SR.
8. Reprezentácia, alkohol, osobné výdavky — upozorni na riziko neuznateľnosti, nie na automatické zamietnutie.
9. Neposkytuj investičné poradenstvo ani právne zmluvy.
''';

  static String formatChatHistory(List<BizBotMessage> messages) {
    if (messages.isEmpty) return '';

    final sorted = List<BizBotMessage>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final lines = sorted.map((m) {
      final role = m.isUser ? 'Používateľ' : 'BizBot';
      final text = m.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty) return null;
      final clipped = text.length > 500 ? '${text.substring(0, 500)}…' : text;
      return '$role: $clipped';
    }).whereType<String>();

    return 'NEDÁVNÝ ROZHOVOR:\n${lines.join('\n')}\n';
  }

  static String formatBusinessContext({
    required UserSettingsModel? settings,
    required List<InvoiceModel> invoices,
    required List<ExpenseModel> expenses,
    required TaxEstimationModel? tax,
    required DateTime now,
  }) {
    final currency = NumberFormat.currency(symbol: '€', locale: 'sk_SK');
    final monthStart = DateTime(now.year, now.month, 1);
    final monthLabel = DateFormat('MMMM yyyy', 'sk').format(now);

    final activeInvoices = invoices
        .where((i) =>
            i.status != InvoiceStatus.draft && i.status != InvoiceStatus.cancelled)
        .toList();

    final monthInvoices =
        activeInvoices.where((i) => i.dateIssued.isAfter(monthStart)).toList();
    final monthExpenses = expenses.where((e) => e.date.isAfter(monthStart)).toList();

    final monthRevenue =
        monthInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final monthCosts = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final unpaid = activeInvoices
        .where((i) => i.status != InvoiceStatus.paid)
        .toList();
    final overdue = unpaid.where((i) => i.dateDue.isBefore(now)).toList();
    final unpaidAmount =
        unpaid.fold(0.0, (sum, i) => sum + i.totalAmount);

    final ytdRevenue = tax?.ytdRevenue ?? 0.0;
    final ytdExpenses = tax?.ytdExpenses ?? 0.0;
    final ytdProfit = tax?.netProfit ?? (ytdRevenue - ytdExpenses);
    final vatLtm = tax?.vatTurnoverLtm ?? 0.0;
    final vatPct = SlovakBusinessReference.vatRegistrationTurnoverEur > 0
        ? (vatLtm / SlovakBusinessReference.vatRegistrationTurnoverEur * 100)
            .clamp(0, 999)
        : 0.0;

    final registerHint = (settings?.registerInfo.trim().isNotEmpty ?? false)
        ? settings!.registerInfo.trim()
        : 'neuvedené (dopln v Nastaveniach → Firemný profil)';

    final buffer = StringBuffer()
      ..writeln('KONTEXT POUŽÍVATEĽA (údaje z aplikácie BizAgent):')
      ..writeln('Firma: ${settings?.companyName.trim().isNotEmpty == true ? settings!.companyName : 'Neznáma'}')
      ..writeln('IČO: ${settings?.companyIco.trim().isNotEmpty == true ? settings!.companyIco : '-'}')
      ..writeln('DIČ: ${settings?.companyDic.trim().isNotEmpty == true ? settings!.companyDic : '-'}')
      ..writeln('Platca DPH: ${settings?.isVatPayer == true ? 'Áno' : 'Nie'}')
      ..writeln('IČ DPH: ${settings?.companyIcDph.trim().isNotEmpty == true ? settings!.companyIcDph : '-'}')
      ..writeln('Zápis / forma podnikania: $registerHint')
      ..writeln()
      ..writeln('MESIAC $monthLabel:')
      ..writeln('- Tržby (faktúry): ${currency.format(monthRevenue)} (${monthInvoices.length} faktúr)')
      ..writeln('- Výdavky: ${currency.format(monthCosts)} (${monthExpenses.length} položiek)')
      ..writeln('- Mesačný výsledok (orientačný): ${currency.format(monthRevenue - monthCosts)}')
      ..writeln()
      ..writeln('ROK ${now.year} (od začiatku roka, orientačný odhad appky):')
      ..writeln('- Tržby YTD: ${currency.format(ytdRevenue)}')
      ..writeln('- Výdavky YTD: ${currency.format(ytdExpenses)}')
      ..writeln('- Zisk YTD (orientačný): ${currency.format(ytdProfit)}')
      ..writeln()
      ..writeln('DPH / OBRAT (12 mesiacov, orientačný):')
      ..writeln('- Obrat LTM: ${currency.format(vatLtm)}')
      ..writeln('- Limit registrácie DPH: ${currency.format(SlovakBusinessReference.vatRegistrationTurnoverEur)}')
      ..writeln('- Využitie limitu (orientačné): ${vatPct.toStringAsFixed(0)} %')
      ..writeln()
      ..writeln('CASHFLOW / FAKTÚRY:')
      ..writeln('- Nezaplatené faktúry: ${unpaid.length} (${currency.format(unpaidAmount)})')
      ..writeln('- Po splatnosti: ${overdue.length}');

    if (overdue.isNotEmpty) {
      buffer.writeln('  Top po splatnosti:');
      for (final inv in overdue.take(3)) {
        final days = now.difference(inv.dateDue).inDays;
        buffer.writeln(
          '  • ${inv.clientName} č.${inv.number}: ${currency.format(inv.totalAmount)} ($days dní)',
        );
      }
    }

    if (monthExpenses.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('POSLEDNÉ VÝDAVKY (max 5):');
      for (final e in monthExpenses.take(5)) {
        buffer.writeln(
          '- ${e.vendorName}: ${currency.format(e.amount)} (${e.category?.displayName ?? 'iné'})',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('SK REFERENČNÝ RÁMEC (všeobecné, nie individuálna rada):');
    buffer.writeln(
      '- SZČO: odvody SP + zdravotná poistenie; daň z príjmov podľa zvoleného režimu.',
    );
    buffer.writeln(
      '- Paušálne vs. skutočné náklady: ovplyvňuje daňový základ — typ nie je v appke, opýtaj sa používateľa.',
    );
    buffer.writeln(
      '- DPH: pri obrate nad limit ${SlovakBusinessReference.vatRegistrationTurnoverEur.toStringAsFixed(0)} € / 12 mes. hrozí povinnosť registrácie platcu.',
    );

    return buffer.toString().trim();
  }

  /// Zostaví finálny prompt s ochranou pred prekročením limitu edge funkcie (10 000 znakov).
  static String buildUserPrompt({
    required String businessContext,
    required String chatHistory,
    required String userMessage,
  }) {
    final core = '''
${systemPrompt()}

$businessContext

$chatHistory
UŽÍVATEĽSKÁ OTÁZKA: ${userMessage.trim()}
''';

    if (core.length <= maxPromptChars) return core.trim();

    // Skráti históriu, potom kontext — otázka a guardrails ostávajú.
    final withoutHistory = '''
${systemPrompt()}

$businessContext

UŽÍVATEĽSKÁ OTÁZKA: ${userMessage.trim()}
''';

    if (withoutHistory.length <= maxPromptChars) return withoutHistory.trim();

    final clippedContext = businessContext.length > 4000
        ? '${businessContext.substring(0, 4000)}\n… [kontext skrátený]'
        : businessContext;

    return '''
${systemPrompt()}

$clippedContext

UŽÍVATEĽSKÁ OTÁZKA: ${userMessage.trim()}
'''.trim();
  }
}