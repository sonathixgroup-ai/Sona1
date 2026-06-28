// lib/models/comment.dart

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentId;
  final DateTime createdAt;
  final Map<String, dynamic>? author;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentId,
    required this.createdAt,
    this.author,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String? ?? '',
      postId: map['post_id'] as String? ?? '',
      authorId: (map['author'] is String) ? (map['author'] as String) : ((map['author'] as Map?)?['id'] as String? ?? ''),
      content: map['content'] as String? ?? '',
      parentId: map['parent_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      author: (map['profiles'] is Map) ? Map<String, dynamic>.from(map['profiles'] as Map) : null,
    );
  }
}
