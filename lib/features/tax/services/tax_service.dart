import 'package:intl/intl.dart';
import '../models/tax_deadline_model.dart';
import '../../settings/models/user_settings_model.dart';

class TaxService {
  List<TaxDeadlineModel> getUpcomingDeadlines(UserSettingsModel settings) {
    final now = DateTime.now();
    final deadlines = <TaxDeadlineModel>[];

    // 1. DPH (VAT) - Monthly payer logic (Simplified for MVP)
    // If user has IČ DPH, we assume they are payer
    if (settings.companyIcDph.isNotEmpty) {
      // Next 25th
      var nextVatDate = DateTime(now.year, now.month, 25);
      if (now.day > 25) {
        nextVatDate = DateTime(now.year, now.month + 1, 25);
      }

      deadlines.add(TaxDeadlineModel(
        title: 'DPH & KV DPH',
        date: nextVatDate,
        description:
            'Podanie a úhrada DPH za ${DateFormat('MMMM', 'sk').format(nextVatDate.subtract(const Duration(days: 20)))}',
        isMajor: true,
      ));
    }

    // 2. Income Tax (Daň z príjmov) - 31.3.
    var incomeTaxDate = DateTime(now.year, 3, 31);
    if (now.isAfter(incomeTaxDate)) {
      incomeTaxDate = DateTime(now.year + 1, 3, 31);
    }
    deadlines.add(TaxDeadlineModel(
      title: 'Daň z príjmov',
      date: incomeTaxDate,
      description: 'Podanie DP FO/PO a úhrada dane',
      isMajor: true,
    ));

    // 3. Social & Health Insurance (Odvody) - 8th / 18th (Simplified as monthly reminder for 8th)
    // Only if not strictly just invoicing app, but good reminder
    var nextSocialDate = DateTime(now.year, now.month, 8);
    if (now.day > 8) {
      nextSocialDate = DateTime(now.year, now.month + 1, 8);
    }
    deadlines.add(TaxDeadlineModel(
      title: 'Odvody do SP',
      date: nextSocialDate,
      description: 'Splatnosť odvodov pre SZČO',
    ));

    // Sort
    deadlines.sort((a, b) => a.date.compareTo(b.date));
    return deadlines;
  }
}
