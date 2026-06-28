// lib/presentation/network/models/reaction_model.dart

class ReactionModel {
  final String id;
  final String userId;
  final String postId;
  final String type;
  final DateTime createdAt;

  ReactionModel({required this.id, required this.userId, required this.postId, required this.type, required this.createdAt});

  factory ReactionModel.fromMap(Map<String, dynamic> m) => ReactionModel(
        id: m['id'] as String? ?? '',
        userId: m['user_id'] as String? ?? '',
        postId: m['post_id'] as String? ?? '',
        type: m['type'] as String? ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
