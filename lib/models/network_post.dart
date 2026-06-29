// lib/models/network_post.dart
class NetworkPost {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String? authorTitle;
  final String content;
  final List<String> imageUrls;
  final List<String>? videoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final bool isPublic;
  final String status; // 'public', 'private', 'connections'
  final String? communityId;
  final int? views;

  NetworkPost({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    this.authorTitle,
    required this.content,
    this.imageUrls = const [],
    this.videoUrls,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isReposted = false,
    this.isPublic = true,
    this.status = 'public',
    this.communityId,
    this.views,
  });

  factory NetworkPost.fromJson(Map<String, dynamic> json) {
    return NetworkPost(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Utilisateur',
      authorAvatar: json['author_avatar'] as String?,
      authorTitle: json['author_title'] as String?,
      content: json['content'] as String? ?? '',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List? ?? [])
          : [],
      videoUrls: json['video_urls'] != null
          ? List<String>.from(json['video_urls'] as List? ?? [])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      repostsCount: json['reposts_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      isReposted: json['is_reposted'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? true,
      status: json['status'] as String? ?? 'public',
      communityId: json['community_id'] as String?,
      views: json['views'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'author_title': authorTitle,
      'content': content,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'reposts_count': repostsCount,
      'is_liked': isLiked,
      'is_saved': isSaved,
      'is_reposted': isReposted,
      'is_public': isPublic,
      'status': status,
      'community_id': communityId,
      'views': views,
    };
  }

  NetworkPost copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatar,
    String? authorTitle,
    String? content,
    List<String>? imageUrls,
    List<String>? videoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isLiked,
    bool? isSaved,
    bool? isReposted,
    bool? isPublic,
    String? status,
    String? communityId,
    int? views,
  }) {
    return NetworkPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorTitle: authorTitle ?? this.authorTitle,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isReposted: isReposted ?? this.isReposted,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      views: views ?? this.views,
    );
  }
}
