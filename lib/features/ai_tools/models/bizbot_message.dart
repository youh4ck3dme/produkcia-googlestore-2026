import 'package:cloud_firestore/cloud_firestore.dart';

class BizBotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const BizBotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  static BizBotMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final text = (data['text'] as String?)?.trim() ?? '';
    final isUser = data['isUser'] == true;

    final clientCreatedAtMs = (data['clientCreatedAt'] as num?)?.toInt();
    final createdAtTs = data['createdAt'];

    DateTime createdAt;
    if (createdAtTs is Timestamp) {
      createdAt = createdAtTs.toDate();
    } else if (clientCreatedAtMs != null) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(clientCreatedAtMs);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return BizBotMessage(
      id: doc.id,
      text: text,
      isUser: isUser,
      createdAt: createdAt,
    );
  }
}

