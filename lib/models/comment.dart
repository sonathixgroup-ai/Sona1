class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;
  final List<Comment> replies; // sous‑commentaires

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Utilisateur',
      userAvatar: json['user_avatar'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      replies: (json['replies'] as List?)
          ?.map((e) => Comment.fromJson(e))
          .toList() ?? [],
    );
  }
}
