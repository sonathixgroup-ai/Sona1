// lib/presentation/network/models/conversation_model.dart

class ConversationModel {
  final String id;
  final String? title;
  final DateTime createdAt;

  ConversationModel({required this.id, this.title, required this.createdAt});

  factory ConversationModel.fromMap(Map<String, dynamic> m) => ConversationModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
