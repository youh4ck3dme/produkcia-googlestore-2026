import 'package:flutter/foundation.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/analytics/models/expense_insight_model.dart';
import 'demo_scenarios.dart';
import 'demo_data_generator.dart';

/// Kompletný demo mode pre prezentácie a testovanie.
/// Aktivácia: triple tap na logo, secret gesture alebo launch parameter.
class DemoModeService extends ChangeNotifier {
  DemoModeService._();
  static final DemoModeService instance = DemoModeService._();

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
    _isDemoMode = true;
    _currentScenario = scenario;
    _injectDemoData();
    notifyListeners();
  }

  /// Deaktivuje demo mód.
  void deactivateDemoMode() {
    _isDemoMode = false;
    _currentScenario = DemoScenario.standard;
    notifyListeners();
  }

  /// Nastaví scenár (bez zmeny stavu isDemoMode).
  void setScenario(DemoScenario scenario) {
    _currentScenario = scenario;
    if (_isDemoMode) _injectDemoData();
    notifyListeners();
  }

  /// Zaznamená tap na logo. Pri trojitom tape do 2 s prepne demo mód.
  void recordLogoTap() {
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
      if (_isDemoMode) _injectDemoData();
      notifyListeners();
    }
  }

  /// Interné „injektovanie“ demo dát – v tejto implementácii len notifikácia.
  /// Skutočné dáta sa vracia cez [getDemoExpenses], [getDemoInvoices], [getDemoInsights].
  void _injectDemoData() {
    notifyListeners();
  }

  /// Vráti demo výdavky pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseModel> getDemoExpenses() {
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateExpenses(_currentScenario);
  }

  /// Vráti demo faktúry pre aktuálny scenár (ak je demo mód zapnutý).
  List<InvoiceModel> getDemoInvoices() {
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInvoices(_currentScenario);
  }

  /// Vráti demo AI insights pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseInsight> getDemoInsights() {
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInsights(_currentScenario);
  }
}
