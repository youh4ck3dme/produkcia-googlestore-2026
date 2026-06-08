import 'package:bizagent/core/services/local_persistence_service.dart';

/// In-memory LocalPersistenceService pre unit testy (offline režim bez Supabase).
class MemoryLocalPersistenceService extends LocalPersistenceService {
  final Map<String, Map<String, dynamic>> _invoices = {};
  final Map<String, Map<String, dynamic>> _expenses = {};

  @override
  List<Map<String, dynamic>> getInvoices() =>
      _invoices.values.map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Future<void> saveInvoice(String id, Map<String, dynamic> data) async {
    _invoices[id] = Map<String, dynamic>.from(data)..['id'] = id;
  }

  @override
  Future<void> deleteInvoice(String id) async {
    _invoices.remove(id);
  }

  @override
  List<Map<String, dynamic>> getExpenses() =>
      _expenses.values.map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Future<void> saveExpense(String id, Map<String, dynamic> data) async {
    _expenses[id] = Map<String, dynamic>.from(data)..['id'] = id;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _expenses.remove(id);
  }
}
