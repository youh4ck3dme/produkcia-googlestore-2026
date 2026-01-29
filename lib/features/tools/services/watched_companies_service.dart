import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final watchedCompaniesServiceProvider = Provider<WatchedCompaniesService>((ref) {
  return WatchedCompaniesService();
});

class WatchedCompaniesService {
  final FirebaseFirestore _db;
  final String? _testUid; // For testing only
  
  String? get _uid => _testUid ?? FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('watched_companies');
  }

  // Constructor for testing injection if needed
  WatchedCompaniesService([FirebaseFirestore? db, this._testUid]) 
      : _db = db ?? FirebaseFirestore.instance;

  /// Watch a company
  Future<void> watch(String icoNorm, String name) async {
    final ref = _ref;
    if (ref == null) throw Exception('User not logged in');
    
    return ref.doc(icoNorm).set({
      'icoNorm': icoNorm,
      'name': name,
      'watchedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Unwatch a company
  Future<void> unwatch(String icoNorm) async {
    final ref = _ref;
    if (ref == null) return;
    
    return ref.doc(icoNorm).delete();
  }

  /// Check if a company is watched
  Stream<bool> isWatched(String icoNorm) {
    final ref = _ref;
    if (ref == null) return Stream.value(false);
    
    return ref.doc(icoNorm).snapshots().map((d) => d.exists);
  }

  /// Get count of watched companies (Future)
  Future<int> getWatchedCount() async {
    final ref = _ref;
    if (ref == null) return 0;
    
    // count() aggregation is cheaper than fetching all docs
    final snapshot = await ref.count().get();
    return snapshot.count ?? 0;
  }

  /// List all watched companies
  Stream<List<Map<String, dynamic>>> listWatched() {
    final ref = _ref;
    if (ref == null) return Stream.value([]);

    return ref
        .orderBy('watchedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }
}
