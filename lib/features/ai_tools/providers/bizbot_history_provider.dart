import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/bizbot_message.dart';

/// História BizBot konverzácie — Supabase (tabuľka `bizbot_messages`).
class BizBotHistoryRepository {
  BizBotHistoryRepository(this._client);

  final SupabaseClient? _client;

  static const _table = 'bizbot_messages';
  static const _thread = 'main';

  Stream<List<BizBotMessage>> streamMessages(String uid, {int limit = 100}) {
    final client = _client;
    if (client == null) return Stream.value(const <BizBotMessage>[]);

    return client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at')
        .limit(limit)
        .map<List<BizBotMessage>>((rows) => rows
            .map((r) => BizBotMessage.fromRow(Map<String, dynamic>.from(r as Map)))
            .toList());
  }

  Future<void> addMessage({
    required String uid,
    required String text,
    required bool isUser,
  }) async {
    await _client?.from(_table).insert({
      'user_id': uid,
      'thread_id': _thread,
      'text': text,
      'is_user': isUser,
    });
  }

  /// Posledné správy pre AI kontext (chronologicky, bez aktuálnej odpovede bota).
  Future<List<BizBotMessage>> fetchRecentMessages(
    String uid, {
    int limit = 8,
  }) async {
    final client = _client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .eq('thread_id', _thread)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (rows as List)
          .map((r) => BizBotMessage.fromRow(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearThread(String uid) async {
    await _client
        ?.from(_table)
        .delete()
        .eq('user_id', uid)
        .eq('thread_id', _thread);
  }
}

final bizBotHistoryRepositoryProvider = Provider<BizBotHistoryRepository>((ref) {
  return BizBotHistoryRepository(
    SupabaseConfig.isReady ? SupabaseConfig.client : null,
  );
});

final bizBotMessagesProvider = StreamProvider<List<BizBotMessage>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const <BizBotMessage>[]);
  final repo = ref.watch(bizBotHistoryRepositoryProvider);
  return repo.streamMessages(user.id);
});
