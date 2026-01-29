import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_repository.dart';
import '../../features/notifications/services/notification_service.dart';

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService(ref);
});

class MonitoringService {
  final Ref _ref;
  StreamSubscription? _notificationSubscription;
  bool _isListening = false;

  MonitoringService(this._ref);

  /// Starts listening to the user's notification collection in Firestore.
  void startListening() {
    if (_isListening) return;

    final authState = _ref.watch(authStateProvider).value;
    if (authState == null || authState.isAnonymous) {
      debugPrint('MonitoringService: Guest or not logged in, skipping.');
      return;
    }

    final uid = authState.uid;
    _isListening = true;

    debugPrint('MonitoringService: Starting Firestore listener for $uid');

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewNotification(change.doc);
        }
      }
    });
  }

  void _handleNewNotification(DocumentSnapshot doc) {
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Zmena u klienta';
    final body = data['body'] ?? 'Zistili sme novú zmenu v obchodnom registri.';
    final type = data['type'] ?? 'unknown';

    debugPrint('MonitoringService: New notification received: $title');

    // Trigger local push notification
    _ref.read(notificationServiceProvider).showNotification(
      id: doc.id.hashCode,
      title: title,
      body: body,
      payload: 'type=$type;id=${doc.id}',
    );
  }

  void stopListening() {
    _notificationSubscription?.cancel();
    _isListening = false;
    debugPrint('MonitoringService: Stopped listening.');
  }
}
