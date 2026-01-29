import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});

class MonitoringService {
  final _db = FirebaseFirestore.instance;
  
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Stream of notifications for the current user
  Stream<List<Map<String, dynamic>>> notifications() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20) // Good practice to limit
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id; // Include doc ID for actions
              return data;
            }).toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    
    // Safety check: ensure we only update our own notifications (optional but good)
    // For now direct update is fine as per rules
    return _db.collection('notifications').doc(id).update({'read': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}
