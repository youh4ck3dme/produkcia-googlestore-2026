import 'package:flutter/material.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/models/expense_category.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/analytics/models/expense_insight_model.dart';
import 'demo_scenarios.dart';

/// Profil demo užívateľa (na mieru špecu).
class DemoUserProfile {
  final String name;
  final String ico;
  final String dic;
  final String businessType;
  final double monthlyRevenue;
  final bool registeredForVat;

  const DemoUserProfile({
    this.name = 'Ján Novák',
    this.ico = '12345678',
    this.dic = '1234567890',
    this.businessType = 'IT Konzultant',
    this.monthlyRevenue = 4500,
    this.registeredForVat = false,
  });
}

/// Orphan transakcia (transakcia bez bločka) pre Receipt Detective.
class DemoOrphanTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String merchantHint;

  const DemoOrphanTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.merchantHint,
  });
}

/// Záznam GPS histórie pre rekonštrukciu.
class DemoLocationEntry {
  final DateTime date;
  final String placeName;
  final double? lat;
  final double? lon;

  const DemoLocationEntry({
    required this.date,
    required this.placeName,
    this.lat,
    this.lon,
  });
}

/// Fake email (účtenka / potvrdenie) pre rekonštrukciu.
class DemoFakeEmail {
  final String subject;
  final String sender;
  final String body;
  final DateTime date;

  const DemoFakeEmail({
    required this.subject,
    required this.sender,
    required this.body,
    required this.date,
  });
}

/// Fake kalendárová udalosť pre rekonštrukciu.
class DemoFakeCalendarEvent {
  final String title;
  final String? location;
  final DateTime date;
  final List<String> attendees;

  const DemoFakeCalendarEvent({
    required this.title,
    this.location,
    required this.date,
    this.attendees = const [],
  });
}

/// Generátor realistických demo dát pre všetky scenáre.
class DemoDataGenerator {
  DemoDataGenerator._();

  static const DemoUserProfile demoUser = DemoUserProfile();

  static const String _demoUserId = 'demo_user_1';

  /// Generuje výdavky podľa scenára (6 mesiacov).
  static List<ExpenseModel> generateExpenses(DemoScenario scenario) {
    final now = DateTime.now();
    final list = <ExpenseModel>[];

    void addRecurring(String vendor, double amount, int dayOfMonth,
        ExpenseCategory category, int monthsBack) {
      for (var m = 0; m < monthsBack; m++) {
        var d = DateTime(now.year, now.month - m, dayOfMonth.clamp(1, 28));
        if (d.isAfter(now)) d = now.subtract(const Duration(days: 1));
        list.add(ExpenseModel(
          id: 'demo_exp_${vendor}_$m',
          userId: _demoUserId,
          vendorName: vendor,
          description: vendor,
          amount: amount,
          date: d,
          category: category,
          categorizationConfidence: 95,
        ));
      }
    }

    void addVariable(String vendor, double min, double max,
        ExpenseCategory category, int countPerMonth, int monthsBack) {
      final range = max - min;
      for (var m = 0; m < monthsBack; m++) {
        for (var i = 0; i < countPerMonth; i++) {
          final amount = min + (range * (i / (countPerMonth + 1)));
          var d = DateTime(now.year, now.month - m, 5 + i * 3);
          if (d.isAfter(now)) d = now.subtract(const Duration(days: 1));
          list.add(ExpenseModel(
            id: 'demo_exp_${vendor}_${m}_$i',
            userId: _demoUserId,
            vendorName: vendor,
            description: vendor,
            amount: amount,
            date: d,
            category: category,
            categorizationConfidence: 90,
          ));
        }
      }
    }

    const monthsBack = 6;

    addRecurring('Nájom kancelária', 450, 1, ExpenseCategory.rent, monthsBack);
    addRecurring('Internet Telekom', 29.99, 5, ExpenseCategory.internet, monthsBack);
    addRecurring('Mobil O2', 35, 10, ExpenseCategory.phone, monthsBack);
    addRecurring('Účtovník', 150, 15, ExpenseCategory.accounting, monthsBack);
    addRecurring('Software subscriptions', 89, 1, ExpenseCategory.software, monthsBack);
    addVariable('PHM', 150, 250, ExpenseCategory.fuel, 4, monthsBack);
    addVariable('Kancelárske potreby', 20, 80, ExpenseCategory.officeSupplies, 2, monthsBack);
    addVariable('Reštaurácie', 15, 45, ExpenseCategory.meals, 8, monthsBack);

    if (scenario == DemoScenario.anomalyDetection) {
      list.add(ExpenseModel(
        id: 'demo_anomaly_1',
        userId: _demoUserId,
        vendorName: 'UNKNOWN VENDOR',
        description: 'Neidentifikovaná transakcia',
        amount: 499.99,
        date: now.subtract(const Duration(days: 3)),
        category: ExpenseCategory.other,
        categorizationConfidence: 10,
      ));
      list.add(ExpenseModel(
        id: 'demo_anomaly_2a',
        userId: _demoUserId,
        vendorName: 'Tesco',
        description: 'Nákup',
        amount: 45.50,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.other,
        categorizationConfidence: 80,
      ));
      list.add(ExpenseModel(
        id: 'demo_anomaly_2b',
        userId: _demoUserId,
        vendorName: 'Tesco',
        description: 'Nákup',
        amount: 45.50,
        date: now.subtract(const Duration(days: 1)),
        category: ExpenseCategory.other,
        categorizationConfidence: 80,
      ));
    }

    return list;
  }

  /// Generuje faktúry podľa scenára.
  static List<InvoiceModel> generateInvoices(DemoScenario scenario) {
    final now = DateTime.now();
    final list = <InvoiceModel>[];

    for (var i = 0; i < 6; i++) {
      final issued = DateTime(now.year, now.month - i, 15);
      final due = issued.add(const Duration(days: 14));
      final amount = 1800.0 + (i % 3) * 200.0;
      list.add(InvoiceModel(
        id: 'demo_inv_$i',
        userId: _demoUserId,
        createdAt: issued,
        number: 'FV-202${5 - i}${100 + i}',
        clientName: i.isEven ? 'Klient Alpha s.r.o.' : 'Klient Beta a.s.',
        dateIssued: issued,
        dateDue: due,
        items: [
          InvoiceItemModel(title: 'Konzultačné služby', amount: amount, vatRate: 0.0),
        ],
        totalAmount: amount,
        status: i < 2 ? InvoiceStatus.paid : InvoiceStatus.sent,
      ));
    }
    return list;
  }

  /// Generuje AI insights (predikcie, daňové odporúčania, anomálie) podľa scenára.
  static List<ExpenseInsight> generateInsights(DemoScenario scenario) {
    final now = DateTime.now();

    switch (scenario) {
      case DemoScenario.standard:
        return [
          ExpenseInsight(
            id: 'demo_insight_1',
            title: 'Predikcia na 30 dní',
            description: 'Očakávané výdavky na základe histórie: cca 1 200 €.',
            icon: Icons.trending_up,
            color: Colors.blue,
            priority: InsightPriority.medium,
            createdAt: now,
            category: 'trend',
          ),
        ];
      case DemoScenario.approachingVat:
        return [
          ExpenseInsight(
            id: 'demo_vat_1',
            title: 'Blížiš sa k DPH limitu',
            description: 'Za posledných 12 mesiacov si na 85 % z limitu 49 790 €. Zváž registráciu plátcu DPH.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            priority: InsightPriority.high,
            createdAt: now,
            category: 'optimization',
          ),
        ];
      case DemoScenario.cashflowCrisis:
        return [
          ExpenseInsight(
            id: 'demo_cash_1',
            title: 'Nízky predpokladaný cashflow',
            description: 'V nasledujúcich 30 dňoch môže byť hotovostný tok pod priemerom. Odporúčame odložiť nepotrebné výdavky.',
            icon: Icons.trending_down,
            color: Colors.red,
            priority: InsightPriority.high,
            createdAt: now,
            category: 'anomaly',
          ),
        ];
      case DemoScenario.taxOptimization:
        return [
          ExpenseInsight(
            id: 'demo_tax_1',
            title: 'Daňová úspora',
            description: 'Úpravou kategórie výdavkov na účtovníctvo a software môžeš ušetriť približne 120 € ročne.',
            icon: Icons.savings_outlined,
            color: Colors.green,
            potentialSavings: 120,
            priority: InsightPriority.medium,
            createdAt: now,
            category: 'optimization',
          ),
        ];
      case DemoScenario.anomalyDetection:
        return [
          ExpenseInsight(
            id: 'demo_anom_1',
            title: 'Podozrivá transakcia',
            description: 'Transakcia 499,99 € u UNKNOWN VENDOR nebola priradená žiadnej kategórii. Skontroluj ju.',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            priority: InsightPriority.high,
            createdAt: now,
            category: 'anomaly',
          ),
          ExpenseInsight(
            id: 'demo_anom_2',
            title: 'Možná duplicita',
            description: 'Dve rovnaké transakcie Tesco 45,50 € v ten istý deň. Over, či nie sú duplicitné.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            priority: InsightPriority.medium,
            createdAt: now,
            category: 'anomaly',
          ),
        ];
      case DemoScenario.receiptMissing:
        return [
          ExpenseInsight(
            id: 'demo_receipt_1',
            title: 'Chýbajúce bločky',
            description: '2 transakcie bez priradenej účtenky. Použi Rekonštrukciu na základe GPS a e-mailov.',
            icon: Icons.receipt_long,
            color: Colors.amber,
            priority: InsightPriority.medium,
            createdAt: now,
            category: 'optimization',
          ),
        ];
    }
  }

  /// Orphan transakcie pre Receipt Detective.
  static List<DemoOrphanTransaction> generateOrphanTransactions() {
    final now = DateTime.now();
    return [
      DemoOrphanTransaction(
        id: 'orphan_1',
        date: now.subtract(const Duration(days: 2)),
        amount: 47.80,
        merchantHint: 'CARD PAYMENT POS',
      ),
      DemoOrphanTransaction(
        id: 'orphan_2',
        date: now.subtract(const Duration(days: 5)),
        amount: 156.30,
        merchantHint: 'SEPA TRANSFER',
      ),
    ];
  }

  /// Fake GPS história (Tesco, čerpacia stanica, kancelária).
  static List<DemoLocationEntry> generateLocationHistory() {
    final now = DateTime.now();
    return [
      DemoLocationEntry(date: now.subtract(const Duration(days: 2)), placeName: 'Tesco Extra'),
      DemoLocationEntry(date: now.subtract(const Duration(days: 2)), placeName: 'OMV'),
      DemoLocationEntry(date: now.subtract(const Duration(days: 5)), placeName: 'Alza.sk - výdajné miesto'),
      DemoLocationEntry(date: now.subtract(const Duration(days: 7)), placeName: 'Reštaurácia Flagship'),
    ];
  }

  /// Fake emaily (potvrdenia objednávok).
  static List<DemoFakeEmail> generateEmails() {
    final now = DateTime.now();
    return [
      DemoFakeEmail(
        subject: 'Vaša objednávka #12345 bola odoslaná',
        sender: 'objednavky@alza.sk',
        body: 'Ďakujeme za nákup. Suma: 156,30 €',
        date: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Fake kalendárové udalosti.
  static List<DemoFakeCalendarEvent> generateCalendarEvents() {
    final now = DateTime.now();
    return [
      DemoFakeCalendarEvent(
        title: 'Meeting s klientom - Alpha s.r.o.',
        location: 'Reštaurácia Flagship',
        date: now.subtract(const Duration(days: 7)),
        attendees: ['jan@alpha.sk'],
      ),
    ];
  }

  /// Veľký dataset pre performance testy (počet výdavkov).
  static List<ExpenseModel> generateLargeDataset(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = now.subtract(Duration(days: i % 180));
      return ExpenseModel(
        id: 'perf_exp_$i',
        userId: _demoUserId,
        vendorName: 'Vendor $i',
        description: 'Test',
        amount: 10.0 + (i % 100),
        date: d,
        category: ExpenseCategory.other,
        categorizationConfidence: 80,
      );
    });
  }
}
