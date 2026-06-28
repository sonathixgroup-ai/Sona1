// lib/presentation/network/models/post_model.dart

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final String content;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.content,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  factory PostModel.fromMap(Map<String, dynamic> m) {
    final media = <String>[];
    if (m['post_media'] is List) {
      for (final it in m['post_media']) {
        if (it is Map<String, dynamic>) {
          final path = it['storage_path'] as String?;
          if (path != null) media.add(path);
        }
      }
    }
    final author = m['profiles'] as Map<String, dynamic>?;
    return PostModel(
      id: m['id'] as String? ?? '',
      authorId: (m['author'] is String) ? m['author'] as String : (author?['id'] as String? ?? ''),
      authorName: author?['display_name'] as String? ?? 'Utilisateur',
      authorPhoto: author?['photo_url'] as String?,
      content: m['content'] as String? ?? '',
      mediaUrls: media,
      likeCount: (m['like_count'] as int?) ?? 0,
      commentCount: (m['comment_count'] as int?) ?? 0,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
