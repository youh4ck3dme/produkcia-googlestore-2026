import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/supabase/supabase_table_store.dart';
import '../../auth/providers/auth_repository.dart';
import '../../notifications/services/notification_service.dart';

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  final service = MonitoringService(ref);

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
  MonitoringService(this._ref);

  final Ref _ref;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _isListening = false;
  String? _userId;
  final Set<String> _seenNotificationIds = {};
  DateTime? _listenStartedAt;

  SupabaseTableStore get _store => _ref.read(supabaseTableStoreProvider);

  void startListening(String uid) {
    if (_isListening && _userId == uid) return;

    stopListening();

    final store = _store;
    if (!store.isAvailable) {
      debugPrint('MonitoringService: Supabase unavailable, skipping.');
      return;
    }

    _userId = uid;
    _isListening = true;
    _listenStartedAt = DateTime.now();
    _seenNotificationIds.clear();

    debugPrint('MonitoringService: Starting Supabase listener for user $uid');

    _subscription = store
        .stream(
          'notifications',
          primaryKey: ['id'],
          eq: {'user_id': uid, 'read': false},
          orderColumn: 'created_at',
          ascending: false,
        )
        .listen(
      (rows) {
        final startedAt = _listenStartedAt;
        if (startedAt == null) return;

        for (final row in rows) {
          final id = row['id'] as String? ?? '';
          if (id.isEmpty || _seenNotificationIds.contains(id)) continue;
          _seenNotificationIds.add(id);

          final createdAt = _parseCreatedAt(row['created_at']);
          if (createdAt != null && createdAt.isAfter(startedAt)) {
            _handleNewNotification(id, row);
          }
        }
      },
      onError: (Object error) {
        debugPrint('MonitoringService Error: $error');
      },
    );
  }

  void _handleNewNotification(String docId, Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row['data'] as Map? ?? {});
    final title = data['title'] as String? ?? 'Zmena v sledovanej firme';
    final body = data['body'] as String? ??
        'Zistili sme novú zmenu v obchodnom registri.';

    debugPrint('MonitoringService: New notification received: $title');

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
    _listenStartedAt = null;
    _seenNotificationIds.clear();
    debugPrint('MonitoringService: Stopped listening.');
  }

  Stream<List<Map<String, dynamic>>> notifications() {
    final uid = _userId ?? _ref.read(authStateProvider).valueOrNull?.id;
    if (uid == null) return Stream.value([]);

    final store = _store;
    if (!store.isAvailable) return Stream.value([]);

    return store
        .stream(
          'notifications',
          primaryKey: ['id'],
          eq: {'user_id': uid},
          orderColumn: 'created_at',
          ascending: false,
        )
        .map(
          (rows) => rows.take(20).map(_rowToViewModel).toList(),
        );
  }

  Map<String, dynamic> _rowToViewModel(Map<String, dynamic> row) {
    final data = Map<String, dynamic>.from(row['data'] as Map? ?? {});
    return {
      'id': row['id'],
      'title': data['title'] ?? 'Upozornenie',
      'body': data['body'] ?? '',
      'read': row['read'] == true,
      'createdAt': row['created_at'],
      'type': data['type'],
    };
  }

  Future<void> markAsRead(String id) async {
    final uid = _userId ?? _ref.read(authStateProvider).valueOrNull?.id;
    if (uid == null) return;

    final store = _store;
    if (!store.isAvailable) return;

    await store.update(
      'notifications',
      {'read': true},
      eq: {'id': id, 'user_id': uid},
    );
  }

  Future<void> markAllAsRead() async {
    final uid = _userId ?? _ref.read(authStateProvider).valueOrNull?.id;
    if (uid == null) return;

    final store = _store;
    if (!store.isAvailable) return;

    await store.update(
      'notifications',
      {'read': true},
      eq: {'user_id': uid, 'read': false},
    );
  }

  DateTime? _parseCreatedAt(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}