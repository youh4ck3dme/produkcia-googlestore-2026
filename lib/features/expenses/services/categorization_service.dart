import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_category.dart';

final categorizationServiceProvider = Provider<CategorizationService>((ref) {
  return CategorizationService(FirebaseFirestore.instance);
});

/// Servis pre automatickú kategorizáciu výdavkov
/// Používa regex pravidlá pre rozpoznanie dodávateľa a návrh kategórie
class CategorizationService {
  final FirebaseFirestore _firestore;

  CategorizationService(this._firestore);

  /// Navrhne kategóriu na základe názvu dodávateľa
  /// Vracia tuple (kategória, confidence 0-100)
  (ExpenseCategory, int) suggestCategory(String vendorName) {
    final vendor = vendorName.toLowerCase().trim();

    // 🚗 PALIVO (95% confidence)
    if (_matchesPattern(vendor, [
      r'slovnaft',
      r'shell',
      r'orlen',
      r'mol\b',
      r'omv',
      r'esso',
      r'lukoil',
      r'benzin',
      r'nafta',
      r'tankovanie',
    ])) {
      return (ExpenseCategory.fuel, 95);
    }

    // 🅿️ PARKOVANIE (90% confidence)
    if (_matchesPattern(vendor, [
      r'parking',
      r'parkovisko',
      r'eps\b',
      r'sms\s*ticket',
      r'parkdots',
      r'paркing',
      r'garaz',
    ])) {
      return (ExpenseCategory.parking, 90);
    }

    // 🔧 SERVIS AUTA (85% confidence)
    if (_matchesPattern(vendor, [
      r'autoservis',
      r'pneuservis',
      r'auto\s*oprava',
      r'mechanik',
      r'servis\s*auto',
      r'stk',
      r'emisna\s*kontrola',
    ])) {
      return (ExpenseCategory.carMaintenance, 85);
    }

    // 🚿 UMÝVANIE AUTA (90% confidence)
    if (_matchesPattern(vendor, [
      r'car\s*wash',
      r'umyvaren',
      r'mycka',
      r'cistenie\s*auta',
    ])) {
      return (ExpenseCategory.carWash, 90);
    }

    // 🛣️ DIAĽNIČNÉ POPLATKY (95% confidence)
    if (_matchesPattern(vendor, [
      r'dialnicn',
      r'edalnica',
      r'vignette',
      r'toll',
      r'mýto',
    ])) {
      return (ExpenseCategory.toll, 95);
    }

    // 🚕 TAXI (95% confidence)
    if (_matchesPattern(vendor, [
      r'taxi',
      r'uber',
      r'bolt',
      r'hopin',
      r'liftago',
    ])) {
      return (ExpenseCategory.taxi, 95);
    }

    // 🛒 STRAVOVANIE - Potraviny (80% confidence)
    if (_matchesPattern(vendor, [
      r'tesco',
      r'kaufland',
      r'lidl',
      r'billa',
      r'coop\s*jednota',
      r'coop\b',
      r'jednota',
      r'fresh',
      r'kraj',
      r'potraviny',
      r'zabka',
    ])) {
      return (ExpenseCategory.meals, 80);
    }

    // 🍽️ STRAVOVANIE - Reštaurácie (75% confidence)
    if (_matchesPattern(vendor, [
      r'restaurant',
      r'restauraci',
      r'pizza',
      r'bistro',
      r'cafe',
      r'kavaren',
      r'mcdonald',
      r'kfc',
      r'burger\s*king',
      r'subway',
      r'napoli',
      r'pizzeria',
    ])) {
      return (ExpenseCategory.meals, 75);
    }

    // 📱 TELEFÓN (95% confidence)
    if (_matchesPattern(vendor, [
      r'orange',
      r'telekom',
      r'o2\b',
      r'4ka',
      r'swan',
      r't-mobile',
      r'vodafone',
    ])) {
      return (ExpenseCategory.phone, 95);
    }

    // 🌐 INTERNET (90% confidence)
    if (_matchesPattern(vendor, [
      r'internet',
      r'slovanet',
      r'antik',
      r'upc',
      r'digi',
      r'wi-fi',
      r'wifi',
    ])) {
      return (ExpenseCategory.internet, 90);
    }

    // 📦 POŠTOVNÉ (95% confidence)
    if (_matchesPattern(vendor, [
      r'slovenska\s*posta',
      r'posta\b',
      r'dhl',
      r'ups',
      r'fedex',
      r'gls',
      r'dpd',
      r'packeta',
      r'zasielkovna',
    ])) {
      return (ExpenseCategory.postage, 95);
    }

    // 🏨 UBYTOVANIE (90% confidence)
    if (_matchesPattern(vendor, [
      r'hotel',
      r'penzion',
      r'ubytovanie',
      r'booking',
      r'airbnb',
      r'hostel',
      r'apartman',
    ])) {
      return (ExpenseCategory.accommodation, 90);
    }

    // ✈️ LETENKY (95% confidence)
    if (_matchesPattern(vendor, [
      r'ryanair',
      r'wizz\s*air',
      r'lufthansa',
      r'austrian',
      r'czech\s*airlines',
      r'airline',
      r'letisko',
      r'airport',
    ])) {
      return (ExpenseCategory.flights, 95);
    }

    // 🚂 VLAKOVÉ LÍSTKY (95% confidence)
    if (_matchesPattern(vendor, [
      r'zssk',
      r'regiojet',
      r'leo\s*express',
      r'vlak',
      r'train',
      r'zeleznic',
    ])) {
      return (ExpenseCategory.trainTickets, 95);
    }

    // 🚌 MHD (90% confidence)
    if (_matchesPattern(vendor, [
      r'mhd',
      r'dpb',
      r'dpm',
      r'dopravny\s*podnik',
      r'imhd',
      r'mestska\s*doprava',
    ])) {
      return (ExpenseCategory.publicTransport, 90);
    }

    // 🏪 KANCELÁRSKE POTREBY (85% confidence)
    if (_matchesPattern(vendor, [
      r'metro',
      r'makro',
      r'office\s*depot',
      r'alza',
      r'datart',
      r'electroworld',
      r'kancelarske\s*potreby',
      r'papiernictvo',
    ])) {
      return (ExpenseCategory.officeSupplies, 85);
    }

    // 💻 SOFTWARE (90% confidence)
    if (_matchesPattern(vendor, [
      r'microsoft',
      r'adobe',
      r'google\s*workspace',
      r'dropbox',
      r'github',
      r'software',
      r'licencia',
      r'subscription',
    ])) {
      return (ExpenseCategory.software, 90);
    }

    // 🛡️ POISTENIE (95% confidence)
    if (_matchesPattern(vendor, [
      r'allianz',
      r'union',
      r'kooperativa',
      r'generali',
      r'wustenrot',
      r'poistovna',
      r'insurance',
      r'poistenie',
    ])) {
      // Rozlíšiť typ poistenia
      if (_matchesPattern(vendor, [r'auto', r'vozidl', r'car'])) {
        return (ExpenseCategory.carInsurance, 95);
      } else if (_matchesPattern(vendor, [r'zdravotn', r'health'])) {
        return (ExpenseCategory.healthInsurance, 95);
      }
      return (ExpenseCategory.liabilityInsurance, 90);
    }

    // ⚖️ PRÁVNE SLUŽBY (95% confidence)
    if (_matchesPattern(vendor, [
      r'advokat',
      r'advokát',
      r'pravnik',
      r'právnik',
      r'kancelari',
      r'kancelári',
      r'notar',
      r'notár',
      r'legal',
      r'law\s*office',
    ])) {
      return (ExpenseCategory.legal, 95);
    }

    // 💼 ÚČTOVNÍCTVO (95% confidence)
    if (_matchesPattern(vendor, [
      r'uctovnictvo',
      r'účtovníctvo',
      r'uctovn',
      r'ucto\b',
      r'accounting',
      r'danovy\s*poradca',
      r'audit',
      r'novak',
      r'novák',
    ])) {
      return (ExpenseCategory.accounting, 95);
    }

    // 📢 MARKETING (85% confidence)
    if (_matchesPattern(vendor, [
      r'marketing',
      r'reklama',
      r'advertising',
      r'facebook\s*ads',
      r'google\s*ads',
      r'instagram',
    ])) {
      return (ExpenseCategory.marketing, 85);
    }

    // 🏠 NÁJOM (90% confidence)
    if (_matchesPattern(vendor, [
      r'najom',
      r'nájom',
      r'rent',
      r'prenajom',
      r'prenájom',
      r'lease',
    ])) {
      return (ExpenseCategory.rent, 90);
    }

    // ⚡ ELEKTRINA (95% confidence)
    if (_matchesPattern(vendor, [
      r'zse',
      r'vsd',
      r'elektrina',
      r'electricity',
      r'energy',
      r'energie',
    ])) {
      return (ExpenseCategory.electricity, 95);
    }

    // 💧 VODA (95% confidence)
    if (_matchesPattern(vendor, [
      r'bvs',
      r'vodaren',
      r'voda',
      r'water',
    ])) {
      return (ExpenseCategory.water, 95);
    }

    // 🔥 KÚRENIE (90% confidence)
    if (_matchesPattern(vendor, [
      r'plyn',
      r'gas',
      r'kurenie',
      r'heating',
      r'spp',
    ])) {
      return (ExpenseCategory.heating, 90);
    }

    // 📚 VZDELÁVANIE (85% confidence)
    if (_matchesPattern(vendor, [
      r'skolenie',
      r'školenie',
      r'kurz',
      r'training',
      r'course',
      r'udemy',
      r'coursera',
      r'kniha',
      r'book',
      r'excel',
      r'martinus',
      r'panta\s*rhei',
      r'knihkupectvo',
    ])) {
      if (_matchesPattern(vendor,
          [r'kniha', r'book', r'martinus', r'panta\s*rhei', r'knihkupectvo'])) {
        return (ExpenseCategory.books, 85);
      }
      return (ExpenseCategory.training, 85);
    }

    // 🏦 BANKOVÉ POPLATKY (95% confidence)
    if (_matchesPattern(vendor, [
      r'banka',
      r'bank',
      r'poplatok',
      r'fee',
      r'slsp',
      r'vub',
      r'tatrabanka',
      r'csob',
      r'unicredit',
    ])) {
      return (ExpenseCategory.bankFees, 95);
    }

    // Ak sa nenašla zhoda, vráť "Ostatné" s nízkou istotou
    return (ExpenseCategory.other, 30);
  }

  /// Helper metóda pre matching regex patterns
  bool _matchesPattern(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Získa históriu kategórií pre daného dodávateľa
  /// (Pre budúce učenie sa z histórie používateľa)
  Future<ExpenseCategory?> getHistoricalCategory(String vendorName,
      {required String userId}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('vendorName', isEqualTo: vendorName)
        .limit(5)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final counts = <ExpenseCategory, int>{};
    for (final doc in snapshot.docs) {
      final categoryStr = doc.data()['category'] as String?;
      final category = expenseCategoryFromString(categoryStr);
      if (category != null) {
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return null;

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Kombinuje AI návrh s historickými dátami
  Future<(ExpenseCategory, int)> suggestCategoryWithHistory(String vendorName,
      {required String userId}) async {
    // Najprv skús AI návrh
    final (aiCategory, aiConfidence) = suggestCategory(vendorName);

    // Potom skús historické dáta
    final historicalCategory =
        await getHistoricalCategory(vendorName, userId: userId);

    // Ak sa zhodujú, zvýš confidence
    if (historicalCategory != null && historicalCategory == aiCategory) {
      return (aiCategory, (aiConfidence + 10).clamp(0, 100));
    }

    // Ak sa nezhodujú, uprednostni historické dáta (ak existujú)
    if (historicalCategory != null) {
      return (historicalCategory, 95);
    }

    // Inak vráť AI návrh
    return (aiCategory, aiConfidence);
  }
}
