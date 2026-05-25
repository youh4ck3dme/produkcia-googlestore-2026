import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_repository.dart';
import '../../notifications/services/notification_service.dart';

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  final service = MonitoringService(ref);
  
  // Watch authStateProvider reactively.
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState != null && !authState.isAnonymous) {
    service.startListening(authState.id);
  } else {
    service.stopListening();
  }

  ref.onDispose(() {
    service.stopListening();
  });

  return service;
});

class MonitoringService {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  bool _isListening = false;
  String? _userId;

  MonitoringService(this._ref);

  /// Starts listening to the user's notifications in Firestore.
  void startListening(String uid) {
    if (_isListening && _userId == uid) return;
    
    // Stop any existing listener
    stopListening();

    _userId = uid;
    _isListening = true;
    final startTime = DateTime.now();

    debugPrint('MonitoringService: Starting Firestore listener for user $uid');

    _subscription = _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          if (!doc.exists) continue;

          final data = doc.data();
          if (data == null) continue;

          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            final createdTime = createdAt.toDate();
            // Only trigger local push notification if created after we started listening
            if (createdTime.isAfter(startTime)) {
              _handleNewNotification(doc.id, data);
            }
          }
        }
      }
    }, onError: (error) {
      debugPrint('MonitoringService Error: $error');
    });
  }

  void _handleNewNotification(String docId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Zmena v sledovanej firme';
    final body = data['body'] ?? 'Zistili sme novú zmenu v obchodnom registri.';

    debugPrint('MonitoringService: New notification received: $title');

    // Trigger local push notification via the local notification service
    _ref.read(notificationServiceProvider).showNotification(
      id: docId.hashCode,
      title: title,
      body: body,
      payload: '/notifications/$docId',
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _userId = null;
    debugPrint('MonitoringService: Stopped listening.');
  }

  /// Stream of notifications for the current user
  Stream<List<Map<String, dynamic>>> notifications() {
    final uid = _userId ?? _ref.read(authStateProvider).valueOrNull?.id;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    return _db.collection('notifications').doc(id).update({'read': true});
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final uid = _userId ?? _ref.read(authStateProvider).valueOrNull?.id;
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
