import 'subscription_guard.dart';

/// User-facing billing text — jeden zdroj pre Play release copy.
class BillingCopy {
  BillingCopy._();

  // --- Locked reasons (krátke, predajné) ---
  static const invoiceLimit =
      'Máte maximum faktúr v bezplatnej verzii. S Pro píšete ďalej.';

  static const aiLocked =
      'AI je v bezplatnej verzii obmedzené. S Pro máte viac analýz.';

  static const exportLocked =
      'Export pre účtovníčku je súčasť Pro.';

  static const watchedCompaniesLocked =
      'Viac sledovaných firiem je v Pro.';

  static const icoLookupLocked =
      'Vyčerpali ste bezplatné IČO vyhľadávania.';

  static const icoPremiumLocked =
      'Rozšírený detail firmy je v Pro.';

  static const watermarkLocked =
      'PDF bez vodoznaku je v Pro.';

  // --- Paywall sheet ---
  static const sheetUnlocksTitle = 'S Pro získate:';

  static const proBenefits = [
    'Neobmedzené faktúry',
    'AI nástroje (BizBot)',
    'Export pre účtovníčku',
    'Rozšírené IČO profily',
  ];

  static const ctaUpgrade = 'Odomknúť Pro';
  static const ctaLater = 'Neskôr';

  // --- Full paywall screen ---
  static const paywallTitle = 'BizAgent Pro';
  static const paywallSubtitle =
      'Faktúry, AI a export bez zbytočných limitov.';

  static const paywallBenefits = [
    'Neobmedzené faktúry',
    'AI nástroje',
    'Export balík (PDF, CSV)',
    'Rozšírené IČO',
  ];

  static String messageFor(BizFeature feature) {
    switch (feature) {
      case BizFeature.createInvoice:
        return invoiceLimit;
      case BizFeature.icoLookup:
        return icoLookupLocked;
      case BizFeature.icoPremiumProfile:
        return icoPremiumLocked;
      case BizFeature.aiAnalysis:
        return aiLocked;
      case BizFeature.exportExcel:
        return exportLocked;
      case BizFeature.removeWatermark:
        return watermarkLocked;
      case BizFeature.watchedCompanies:
        return watchedCompaniesLocked;
    }
  }

  static String titleFor(BizFeature feature) {
    switch (feature) {
      case BizFeature.createInvoice:
        return 'Limit faktúr';
      case BizFeature.aiAnalysis:
        return 'AI nástroje';
      case BizFeature.exportExcel:
        return 'Export';
      case BizFeature.icoLookup:
      case BizFeature.icoPremiumProfile:
        return 'IČO detail';
      case BizFeature.watchedCompanies:
        return 'Sledovanie firiem';
      case BizFeature.removeWatermark:
        return 'Bez vodoznaku';
    }
  }
}
