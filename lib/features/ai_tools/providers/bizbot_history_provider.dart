import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/bizbot_message.dart';

class BizBotHistoryRepository {
  BizBotHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messagesCol(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bizbot_threads')
        .doc('default')
        .collection('messages');
  }

  Stream<List<BizBotMessage>> streamMessages(String uid, {int limit = 100}) {
    return _messagesCol(uid)
        .orderBy('clientCreatedAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs.map(BizBotMessage.fromDoc).toList());
  }

  Future<void> addMessage({
    required String uid,
    required String text,
    required bool isUser,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _messagesCol(uid).add({
      'text': text,
      'isUser': isUser,
      'clientCreatedAt': nowMs,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearThread(String uid) async {
    final col = _messagesCol(uid);
    final snap = await col.get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

final bizBotHistoryRepositoryProvider = Provider<BizBotHistoryRepository>((ref) {
  return BizBotHistoryRepository(FirebaseFirestore.instance);
});

final bizBotMessagesProvider = StreamProvider<List<BizBotMessage>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const <BizBotMessage>[]);
  final repo = ref.watch(bizBotHistoryRepositoryProvider);
  return repo.streamMessages(user.id);
});

