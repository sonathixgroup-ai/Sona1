// lib/presentation/network/models/message_model.dart

class MessageModel {
  final String id;
  final String conversationId;
  final String senderProfileId;
  final String? content;
  final Map<String, dynamic>? media;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderProfileId,
    this.content,
    this.media,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> m) => MessageModel(
        id: m['id'] as String? ?? '',
        conversationId: m['conversation_id'] as String? ?? '',
        senderProfileId: m['sender_profile_id'] as String? ?? '',
        content: m['content'] as String?,
        media: m['media'] as Map<String, dynamic>?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
        deliveredAt: m['delivered_at'] == null ? null : DateTime.tryParse(m['delivered_at'] as String),
        readAt: m['read_at'] == null ? null : DateTime.tryParse(m['read_at'] as String),
      );
}
