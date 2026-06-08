import 'dart:async';
import 'package:bizagent/features/ai_tools/models/bizbot_message.dart';
import 'package:bizagent/features/ai_tools/providers/bizbot_history_provider.dart';

/// Fake BizBot história pre widget testy (in-memory, bez Supabase).
class FakeBizBotHistoryRepository extends BizBotHistoryRepository {
  FakeBizBotHistoryRepository() : super(null);

  final _messages = <BizBotMessage>[];
  final _controller = StreamController<List<BizBotMessage>>.broadcast();

  @override
  Stream<List<BizBotMessage>> streamMessages(String uid, {int limit = 100}) {
    Future.microtask(() => _controller.add(List.unmodifiable(_messages)));
    return _controller.stream;
  }

  @override
  Future<void> addMessage({
    required String uid,
    required String text,
    required bool isUser,
  }) async {
    _messages.add(BizBotMessage(
      id: 'msg-${_messages.length}',
      text: text,
      isUser: isUser,
      createdAt: DateTime.now(),
    ));
    _controller.add(List.unmodifiable(_messages));
  }

  @override
  Future<void> clearThread(String uid) async {
    _messages.clear();
    _controller.add(const []);
  }
}
