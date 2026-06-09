import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/supabase/supabase_table_store.dart';
import '../../../core/services/local_persistence_service.dart';
import '../models/invoice_model.dart';

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  return InvoicesRepository(
    SupabaseConfig.isReady
        ? SupabaseTableStore.fromClient(SupabaseConfig.client)
        : null,
    persistence,
  );
});

/// Faktúry — Supabase Postgres (tabuľka `invoices`) + lokálna Hive cache.
class InvoicesRepository {
  final SupabaseTableStore? _store;
  final LocalPersistenceService _persistence;

  InvoicesRepository(this._store, this._persistence);

  static const _table = 'invoices';

  List<InvoiceModel> _localInvoices(String userId) {
    return _persistence
        .getInvoices()
        .map((data) => InvoiceModel.fromMap(data, data['id'] ?? ''))
        .where((invoice) => invoice.userId == userId)
        .where((invoice) => !invoice.isDeleted)
        .toList();
  }

  InvoiceModel _rowToInvoice(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row['data'] as Map);
    data['id'] = row['id'];
    return InvoiceModel.fromMap(data, row['id'] as String);
  }

  Map<String, dynamic> _invoiceToRow(String userId, InvoiceModel invoice, String id) {
    final data = invoice.toMap();
    data['id'] = id;
    return {
      'id': id,
      'user_id': userId,
      'data': data,
      'date_issued': data['dateIssued'],
      'status': data['status'],
      'is_deleted': invoice.isDeleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<List<InvoiceModel>> getInvoices(String userId) async {
    final local = _localInvoices(userId);
    final store = _store;
    if (store == null || !store.isAvailable) return local;

    try {
      final rows = await store.select(
        _table,
        eq: {'user_id': userId, 'is_deleted': false},
        orderColumn: 'date_issued',
        ascending: false,
      );

      final remote = rows.map((row) {
        final invoice = _rowToInvoice(row);
        final cache = Map<String, dynamic>.from(row['data'] as Map);
        cache['id'] = invoice.id;
        _persistence.saveInvoice(invoice.id, cache);
        return invoice;
      }).toList();

      return remote;
    } catch (_) {
      return local;
    }
  }

  Stream<List<InvoiceModel>> watchInvoices(String userId) async* {
    yield _localInvoices(userId);

    final store = _store;
    if (store == null || !store.isAvailable) return;

    final stream = store.stream(
      _table,
      primaryKey: ['id'],
      eq: {'user_id': userId},
      orderColumn: 'date_issued',
      ascending: false,
    );

    await for (final rows in stream) {
      final invoices = rows
          .where((row) => row['is_deleted'] != true)
          .map((row) {
        final invoice = _rowToInvoice(row);
        final cache = Map<String, dynamic>.from(row['data'] as Map);
        cache['id'] = invoice.id;
        _persistence.saveInvoice(invoice.id, cache);
        return invoice;
      }).toList();

      yield invoices;
    }
  }

  Future<void> addInvoice(String userId, InvoiceModel invoice) async {
    final id = invoice.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : invoice.id;
    final data = invoice.toMap();
    data['id'] = id;
    await _persistence.saveInvoice(id, data);

    await _store?.upsert(_table, _invoiceToRow(userId, invoice, id));
  }

  Future<void> updateInvoice(String userId, InvoiceModel invoice) async {
    final data = invoice.toMap();
    data['id'] = invoice.id;
    await _persistence.saveInvoice(invoice.id, data);

    await _store?.upsert(_table, _invoiceToRow(userId, invoice, invoice.id));
  }

  Future<void> updateInvoiceStatus(
      String userId, String invoiceId, InvoiceStatus status) async {
    final localInvoices = _persistence.getInvoices();
    final index = localInvoices.indexWhere((inv) => inv['id'] == invoiceId);
    Map<String, dynamic>? updated;
    if (index != -1) {
      localInvoices[index]['status'] = status.name;
      updated = Map<String, dynamic>.from(localInvoices[index]);
      await _persistence.saveInvoice(invoiceId, updated);
    }

    final store = _store;
    if (store == null || !store.isAvailable) return;

    await store.update(
      _table,
      {
        'status': status.name,
        if (updated != null) 'data': updated,
        'updated_at': DateTime.now().toIso8601String(),
      },
      eq: {'id': invoiceId, 'user_id': userId},
    );
  }

  Future<void> deleteInvoice(String userId, String invoiceId) async {
    await _persistence.deleteInvoice(invoiceId);
    await _store?.delete(
      _table,
      eq: {'id': invoiceId, 'user_id': userId},
    );
  }
}
