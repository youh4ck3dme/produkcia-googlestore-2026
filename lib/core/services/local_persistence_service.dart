import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalPersistenceService {
  static const String invoicesBoxName = 'invoices_box';
  static const String expensesBoxName = 'expenses_box';
  static const String settingsBoxName = 'settings_box';
  static const String businessProfileKey = 'business_profile';

  Future<void> init() async {
    await Hive.openBox(invoicesBoxName);
    await Hive.openBox(expensesBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // --- Invoices ---
  
  List<Map<String, dynamic>> getInvoices() {
    final box = Hive.box(invoicesBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveInvoice(String id, Map<String, dynamic> data) async {
    final box = Hive.box(invoicesBoxName);
    await box.put(id, data);
  }

  Future<void> deleteInvoice(String id) async {
    final box = Hive.box(invoicesBoxName);
    await box.delete(id);
  }

  Future<void> clearInvoices() async {
    final box = Hive.box(invoicesBoxName);
    await box.clear();
  }

  // --- Expenses ---

  List<Map<String, dynamic>> getExpenses() {
    final box = Hive.box(expensesBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveExpense(String id, Map<String, dynamic> data) async {
    final box = Hive.box(expensesBoxName);
    await box.put(id, data);
  }

  Future<void> deleteExpense(String id) async {
    final box = Hive.box(expensesBoxName);
    await box.delete(id);
  }

  // --- Settings ---
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(settingsBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(key, value);
  }

  // --- Business Profile ---
  
  Map<String, dynamic>? getBusinessProfile() {
    final box = Hive.box(settingsBoxName);
    final data = box.get(businessProfileKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> saveBusinessProfile(Map<String, dynamic> data) async {
    final box = Hive.box(settingsBoxName);
    await box.put(businessProfileKey, data);
  }

  Future<void> clearAll() async {
    await Hive.box(invoicesBoxName).clear();
    await Hive.box(expensesBoxName).clear();
    await Hive.box(settingsBoxName).clear();
  }
}

final localPersistenceServiceProvider = Provider<LocalPersistenceService>((ref) {
  return LocalPersistenceService();
});
