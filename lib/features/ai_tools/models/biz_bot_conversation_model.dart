import '../../../core/models/soft_delete_model.dart';

class BizBotMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // For additional data like attachments

  BizBotMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory BizBotMessageModel.fromMap(Map<String, dynamic> map) {
    return BizBotMessageModel(
      id: map['id'] ?? '',
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class BizBotConversationModel extends SoftDeleteModel {
  final String title;
  final List<BizBotMessageModel> messages;
  final DateTime lastActivity;
  final int messageCount;

  BizBotConversationModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    super.deletedAt,
    super.deleteReason,
    required this.title,
    required this.messages,
    required this.lastActivity,
    required this.messageCount,
  });

  @override
  BizBotConversationModel copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? deleteReason,
    String? title,
    List<BizBotMessageModel>? messages,
    DateTime? lastActivity,
    int? messageCount,
  }) {
    return BizBotConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt,
      deleteReason: deleteReason,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  factory BizBotConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return BizBotConversationModel(
      id: id,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(), // fallback
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'])
          : null,
      deleteReason: map['deleteReason'],
      title: map['title'] ?? 'Bez názvu',
      messages: (map['messages'] as List<dynamic>?)
              ?.map((x) => BizBotMessageModel.fromMap(x))
              .toList() ??
          [],
      lastActivity: map['lastActivity'] != null
          ? DateTime.parse(map['lastActivity'])
          : DateTime.now(),
      messageCount: map['messageCount'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      ...super.toFirestore(),
      'title': title,
      'messages': messages.map((x) => x.toMap()).toList(),
      'lastActivity': lastActivity.toIso8601String(),
      'messageCount': messageCount,
    };
  }
}
