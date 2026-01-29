import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing soft delete operations following Google/Firebase data retention policies
class SoftDeleteService {
  final FirebaseFirestore _firestore;

  SoftDeleteService(this._firestore);

  /// Soft delete an item by marking it as deleted
  Future<void> softDeleteItem(
    String collection,
    String userId,
    String itemId, {
    String? reason,
  }) async {
    final docRef = _firestore.collection(collection).doc(userId).collection('items').doc(itemId);

    await docRef.update({
      'deletedAt': FieldValue.serverTimestamp(),
      'deleteReason': reason,
    });
  }

  /// Restore a soft deleted item
  Future<void> restoreItem(String collection, String userId, String itemId) async {
    final docRef = _firestore.collection(collection).doc(userId).collection('items').doc(itemId);

    await docRef.update({
      'deletedAt': FieldValue.delete(),
      'deleteReason': FieldValue.delete(),
    });
  }

  /// Permanently delete items that are older than 7 days
  Future<void> cleanupExpiredItems(String collection, String userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .where('deletedAt', isLessThan: sevenDaysAgo);

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Get all soft deleted items that can still be restored
  Stream<List<Map<String, dynamic>>> getTrashItems(String collection, String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .where('deletedAt', isGreaterThan: sevenDaysAgo)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              'data': doc.data(),
              'collection': collection,
            }).toList());
  }

  /// Get count of items in trash
  Stream<int> getTrashCount(String collection, String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .where('deletedAt', isGreaterThan: sevenDaysAgo)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Permanently delete a specific item (admin function)
  Future<void> permanentDeleteItem(String collection, String userId, String itemId) async {
    await _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  /// Empty trash - permanently delete all soft deleted items
  Future<void> emptyTrash(String collection, String userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final query = _firestore
        .collection(collection)
        .doc(userId)
        .collection('items')
        .where('deletedAt', isGreaterThan: sevenDaysAgo);

    final snapshot = await query.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}

// Collection names for different item types
class SoftDeleteCollections {
  static const String invoices = 'soft_deleted_invoices';
  static const String bizBotConversations = 'soft_deleted_bizbot_conversations';
  static const String notepadItems = 'soft_deleted_notepad_items';
}

// Provider for the soft delete service
final softDeleteServiceProvider = Provider<SoftDeleteService>((ref) {
  return SoftDeleteService(FirebaseFirestore.instance);
});
