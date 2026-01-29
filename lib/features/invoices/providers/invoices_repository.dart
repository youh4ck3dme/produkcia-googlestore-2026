import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_persistence_service.dart';
import '../models/invoice_model.dart';

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  final persistence = ref.watch(localPersistenceServiceProvider);
  return InvoicesRepository(FirebaseFirestore.instance, persistence);
});

class InvoicesRepository {
  final FirebaseFirestore _firestore;
  final LocalPersistenceService _persistence;

  InvoicesRepository(this._firestore, this._persistence);

  Future<List<InvoiceModel>> getInvoices(String userId) async {
    // 1. Try local data first for immediate UI response
    final localData = _persistence.getInvoices();
    final localInvoices = localData
        .map((data) => InvoiceModel.fromMap(data, data['id'] ?? ''))
        .where((invoice) => !invoice.isDeleted) // Filter out soft deleted
        .toList();

    try {
      // 2. Fetch from Firestore (will work offline if persistence enabled in Firestore,
      // but Hive gives us more control over explicit sync)
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .orderBy('dateIssued', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      final remoteInvoices = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        final invoice = InvoiceModel.fromMap(data, doc.id);
        // Only save to local cache if not soft deleted
        if (!invoice.isDeleted) {
          _persistence.saveInvoice(doc.id, data);
        }
        return invoice;
      }).where((invoice) => !invoice.isDeleted).toList(); // Filter out soft deleted

      return remoteInvoices;
    } catch (e) {
      // Return local if remote fails
      return localInvoices;
    }
  }

  Stream<List<InvoiceModel>> watchInvoices(String userId) async* {
    // Emit local first (filter out soft deleted)
    final localData = _persistence.getInvoices();
    yield localData
        .map((data) => InvoiceModel.fromMap(data, data['id'] ?? ''))
        .where((invoice) => !invoice.isDeleted)
        .toList();

    final stream = _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .orderBy('dateIssued', descending: true)
        .snapshots();

    await for (final snapshot in stream) {
      final invoices = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        final invoice = InvoiceModel.fromMap(data, doc.id);
        // Only save to local cache if not soft deleted
        if (!invoice.isDeleted) {
          _persistence.saveInvoice(doc.id, data);
        }
        return invoice;
      }).where((invoice) => !invoice.isDeleted).toList(); // Filter out soft deleted

      yield invoices;
    }
  }

  Future<void> addInvoice(String userId, InvoiceModel invoice) async {
    // Optimistic local save
    final id = invoice.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : invoice.id;
    final data = invoice.toMap();
    data['id'] = id;
    await _persistence.saveInvoice(id, data);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(id)
        .set(invoice.toMap());
  }

  Future<void> updateInvoice(String userId, InvoiceModel invoice) async {
    final data = invoice.toMap();
    data['id'] = invoice.id;
    await _persistence.saveInvoice(invoice.id, data);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoice.id)
        .update(invoice.toMap());
  }

  Future<void> updateInvoiceStatus(
      String userId, String invoiceId, InvoiceStatus status) async {
    // Update local cache first
    final localInvoices = _persistence.getInvoices();
    final index = localInvoices.indexWhere((inv) => inv['id'] == invoiceId);
    if (index != -1) {
      localInvoices[index]['status'] = status.name;
      await _persistence.saveInvoice(invoiceId, localInvoices[index]);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .update({'status': status.name});
  }

  Future<void> deleteInvoice(String userId, String invoiceId) async {
    await _persistence.deleteInvoice(invoiceId);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .delete();
  }
}
