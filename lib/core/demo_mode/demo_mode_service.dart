import 'package:flutter/foundation.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/analytics/models/expense_insight_model.dart';
import '../services/local_persistence_service.dart';
import 'demo_scenarios.dart';
import 'demo_data_generator.dart';

/// Kompletný demo mode pre prezentácie a testovanie.
/// Aktivácia: triple tap na logo, secret gesture alebo launch parameter.
class DemoModeService extends ChangeNotifier {
  DemoModeService._();
  static final DemoModeService instance = DemoModeService._();

  LocalPersistenceService? persistence;

  bool _isDemoMode = false;
  DemoScenario _currentScenario = DemoScenario.standard;

  /// Počet nedávnych tapov na logo (pre triple-tap).
  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;
  static const _tripleTapWindow = Duration(seconds: 2);

  bool get isDemoMode => _isDemoMode;
  DemoScenario get currentScenario => _currentScenario;

  /// Aktivuje demo mód so zvoleným scenárom.
  void activateDemoMode(DemoScenario scenario) {
    if (kReleaseMode) return;
    _isDemoMode = true;
    _currentScenario = scenario;
    _injectDemoData();
    notifyListeners();
  }

  /// Deaktivuje demo mód.
  void deactivateDemoMode() {
    if (kReleaseMode) return;
    _isDemoMode = false;
    _currentScenario = DemoScenario.standard;
    _clearDemoData();
    notifyListeners();
  }

  /// Nastaví scenár (bez zmeny stavu isDemoMode).
  void setScenario(DemoScenario scenario) {
    if (kReleaseMode) return;
    _currentScenario = scenario;
    if (_isDemoMode) _injectDemoData();
    notifyListeners();
  }

  /// Zaznamená tap na logo. Pri trojitom tape do 2 s prepne demo mód.
  void recordLogoTap() {
    if (kReleaseMode) return;
    final now = DateTime.now();
    if (_lastLogoTapTime != null &&
        now.difference(_lastLogoTapTime!) > _tripleTapWindow) {
      _logoTapCount = 0;
    }
    _lastLogoTapTime = now;
    _logoTapCount++;
    if (_logoTapCount >= 3) {
      _logoTapCount = 0;
      _isDemoMode = !_isDemoMode;
      if (_isDemoMode) {
        _injectDemoData();
      } else {
        _clearDemoData();
      }
      notifyListeners();
    }
  }

  /// Vymaže demo dáta z lokálneho úložiska.
  void _clearDemoData() {
    persistence?.clearInvoices();
    persistence?.clearExpenses();
  }

  /// Interné „injektovanie“ demo dát – uložíme ich do lokálneho úložiska Hive.
  void _injectDemoData() {
    final p = persistence;
    if (p == null) return;

    // Najprv vyčistíme staré demo/lokálne dáta
    _clearDemoData();

    // Generovanie a zápis faktúr do Hive
    final demoInvoices = DemoDataGenerator.generateInvoices(_currentScenario);
    for (final invoice in demoInvoices) {
      final data = invoice.toMap();
      data['id'] = invoice.id;
      p.saveInvoice(invoice.id, data);
    }

    // Generovanie a zápis výdavkov do Hive
    final demoExpenses = DemoDataGenerator.generateExpenses(_currentScenario);
    for (final expense in demoExpenses) {
      final data = expense.toMap();
      data['id'] = expense.id;
      p.saveExpense(expense.id, data);
    }
  }

  /// Vráti demo výdavky pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseModel> getDemoExpenses() {
    if (kReleaseMode) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateExpenses(_currentScenario);
  }

  /// Vráti demo faktúry pre aktuálny scenár (ak je demo mód zapnutý).
  List<InvoiceModel> getDemoInvoices() {
    if (kReleaseMode) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInvoices(_currentScenario);
  }

  /// Vráti demo AI insights pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseInsight> getDemoInsights() {
    if (kReleaseMode) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInsights(_currentScenario);
  }
}
