import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/analytics/models/expense_insight_model.dart';
import '../services/local_persistence_service.dart';
import '../config/play_release_scope.dart';
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

  /// Simuluje release build v testoch (Play review: žiadne demo dáta bez vedomia).
  @visibleForTesting
  static bool debugSimulateReleaseMode = false;

  bool get _demoMutationBlocked =>
      kReleaseMode || debugSimulateReleaseMode || PlayReleaseScope.playMvp;

  /// Reset stavu medzi testami (nevolaj v produkcii).
  @visibleForTesting
  Future<void> resetForTesting() async {
    debugSimulateReleaseMode = false;
    _isDemoMode = false;
    _currentScenario = DemoScenario.standard;
    _logoTapCount = 0;
    _lastLogoTapTime = null;
    await _clearDemoData();
    notifyListeners();
  }

  /// Aktivuje demo mód so zvoleným scenárom.
  Future<void> activateDemoMode(DemoScenario scenario) async {
    if (_demoMutationBlocked) return;
    _isDemoMode = true;
    _currentScenario = scenario;
    await _injectDemoData();
    notifyListeners();
  }

  /// Deaktivuje demo mód.
  Future<void> deactivateDemoMode() async {
    if (_demoMutationBlocked) return;
    _isDemoMode = false;
    _currentScenario = DemoScenario.standard;
    await _clearDemoData();
    notifyListeners();
  }

  /// Nastaví scenár (bez zmeny stavu isDemoMode).
  Future<void> setScenario(DemoScenario scenario) async {
    if (_demoMutationBlocked) return;
    _currentScenario = scenario;
    if (_isDemoMode) await _injectDemoData();
    notifyListeners();
  }

  /// Zaznamená tap na logo. Pri trojitom tape do 2 s prepne demo mód.
  void recordLogoTap() {
    if (_demoMutationBlocked) return;
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
        unawaited(_injectDemoData());
      } else {
        unawaited(_clearDemoData());
      }
      notifyListeners();
    }
  }

  /// Vymaže demo dáta z lokálneho úložiska.
  Future<void> _clearDemoData() async {
    final p = persistence;
    if (p == null) return;
    await p.clearInvoices();
    await p.clearExpenses();
  }

  /// Interné „injektovanie“ demo dát – uložíme ich do lokálneho úložiska Hive.
  Future<void> _injectDemoData() async {
    final p = persistence;
    if (p == null) return;

    // Najprv vyčistíme staré demo/lokálne dáta
    await _clearDemoData();

    // Generovanie a zápis faktúr do Hive
    final demoInvoices = DemoDataGenerator.generateInvoices(_currentScenario);
    for (final invoice in demoInvoices) {
      final data = invoice.toMap();
      data['id'] = invoice.id;
      await p.saveInvoice(invoice.id, data);
    }

    // Generovanie a zápis výdavkov do Hive
    final demoExpenses = DemoDataGenerator.generateExpenses(_currentScenario);
    for (final expense in demoExpenses) {
      final data = expense.toMap();
      data['id'] = expense.id;
      await p.saveExpense(expense.id, data);
    }
  }

  /// Vráti demo výdavky pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseModel> getDemoExpenses() {
    if (_demoMutationBlocked) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateExpenses(_currentScenario);
  }

  /// Vráti demo faktúry pre aktuálny scenár (ak je demo mód zapnutý).
  List<InvoiceModel> getDemoInvoices() {
    if (_demoMutationBlocked) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInvoices(_currentScenario);
  }

  /// Vráti demo AI insights pre aktuálny scenár (ak je demo mód zapnutý).
  List<ExpenseInsight> getDemoInsights() {
    if (_demoMutationBlocked) return [];
    if (!_isDemoMode) return [];
    return DemoDataGenerator.generateInsights(_currentScenario);
  }
}
