// lib/presentation/network/models/bookmark_model.dart

class BookmarkModel {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  BookmarkModel({required this.id, required this.userId, required this.postId, required this.createdAt});

  factory BookmarkModel.fromMap(Map<String, dynamic> m) => BookmarkModel(
        id: m['id'] as String? ?? '',
        userId: m['user_id'] as String? ?? '',
        postId: m['post_id'] as String? ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
