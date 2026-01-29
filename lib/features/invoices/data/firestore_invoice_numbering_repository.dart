// lib/features/invoices/data/firestore_invoice_numbering_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invoice_numbering_repository.dart';

class FirestoreInvoiceNumberingRepository
    implements InvoiceNumberingRepository {
  FirestoreInvoiceNumberingRepository({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _fs = firestore,
        _prefs = prefs;

  final FirebaseFirestore _fs;
  final SharedPreferences _prefs;

  String _poolKey(int year) => 'invoice_number_pool_$year';

  @override
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  }) async {
    final docRef = _fs.doc('users/$uid/counters/invoice_$year');

    return _fs.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final current = (snap.data()?['seq'] as int?) ?? 0;
      final start = current + 1;
      final end = current + blockSize;

      tx.set(docRef, {'seq': end}, SetOptions(merge: true));

      return ReservedBlock(start: start, end: end);
    });
  }

  @override
  Future<LocalPool?> loadLocalPool(int year) async {
    final s = _prefs.getString(_poolKey(year));
    if (s == null || s.isEmpty) return null;
    try {
      return LocalPool.decode(s);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLocalPool(LocalPool pool) async {
    await _prefs.setString(_poolKey(pool.year), pool.encode());
  }
}
