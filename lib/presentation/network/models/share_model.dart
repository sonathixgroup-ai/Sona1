// lib/presentation/network/models/share_model.dart

class ShareModel {
  final String id;
  final String userId;
  final String postId;
  final String targetType; // 'feed'|'message'|'group'
  final String? targetId;
  final DateTime createdAt;

  ShareModel({required this.id, required this.userId, required this.postId, required this.targetType, this.targetId, required this.createdAt});

  factory ShareModel.fromMap(Map<String, dynamic> m) => ShareModel(
        id: m['id'] as String? ?? '',
        userId: m['user_id'] as String? ?? '',
        postId: m['post_id'] as String? ?? '',
        targetType: m['target_type'] as String? ?? 'feed',
        targetId: m['target_id'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
