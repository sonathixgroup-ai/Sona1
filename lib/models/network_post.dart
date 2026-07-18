// lib/models/network_post.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

@immutable
class NetworkPost {
  // ... (Garde tes champs actuels identiques)
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String? authorTitle;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int? views;
  final bool isLiked;
  final bool isSaved;
  final bool isReposted;
  final bool isPinned;
  final String status;
  final bool isPublic;
  final String? communityId;

  const NetworkPost({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    this.authorTitle,
    required this.content,
    required this.mediaUrls,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isReposted = false,
    this.isPinned = false,
    this.status = 'public',
    this.isPublic = true,
    this.communityId,
    this.views,
  });

  // ─── NOUVEAU GETTER : Sécurise l'affichage de la vignette ───
  String? get primaryMediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;

  // ─── Logique média existante ───
  static bool _hasExtension(String url, List<String> extensions) {
    final cleanUrl = url.split('?').first.split('#').first.toLowerCase();
    return extensions.any((ext) => cleanUrl.endsWith(ext));
  }

  static bool _isImage(String url) => _hasExtension(url, ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']);
  static bool _isVideo(String url) => _hasExtension(url, ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v']);

  List<String> get imageUrls => mediaUrls.where(_isImage).toList();
  List<String> get videoUrls => mediaUrls.where(_isVideo).toList();

  bool get hasImages => imageUrls.isNotEmpty;
  bool get hasVideos => videoUrls.isNotEmpty;
  bool get hasMedia => mediaUrls.isNotEmpty;

  // ─── Factory avec gestion robuste des erreurs JSON ───
  factory NetworkPost.fromJson(Map<String, dynamic> json) {
    List<String> mediaUrls = [];
    
    // Priorité à media_urls (nouveau format), sinon fusion image+video
    if (json['media_urls'] != null) {
      mediaUrls = List<String>.from(json['media_urls'] as List? ?? []);
    } else {
      final images = json['image_urls'] is List ? List<String>.from(json['image_urls']) : <String>[];
      final videos = json['video_urls'] is List ? List<String>.from(json['video_urls']) : <String>[];
      mediaUrls = [...images, ...videos];
    }

    return NetworkPost(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? json['profiles']?['display_name']?.toString() ?? 'Utilisateur',
      authorAvatar: json['author_avatar']?.toString() ?? json['profiles']?['photo_url']?.toString(),
      authorTitle: json['author_title']?.toString() ?? json['profiles']?['profession']?.toString(),
      content: json['content']?.toString() ?? '',
      mediaUrls: mediaUrls,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      repostsCount: (json['reposts_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      isReposted: json['is_reposted'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      status: json['status']?.toString() ?? 'public',
      isPublic: json['is_public'] as bool? ?? true,
      communityId: json['community_id']?.toString(),
      views: (json['views'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'content': content,
    'media_urls': mediaUrls,
    'created_at': createdAt.toIso8601String(),
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'reposts_count': repostsCount,
    'is_liked': isLiked,
    'community_id': communityId,
    // ... ajoute les autres champs si nécessaire pour tes updates serveurs
  };

  // ... (Garde ton copyWith, formattedDate, et opérateurs ==/hashCode intacts)
  NetworkPost copyWith({
    String? id, String? userId, String? authorName, String? authorAvatar, String? authorTitle,
    String? content, List<String>? mediaUrls, DateTime? createdAt, DateTime? updatedAt,
    int? likesCount, int? commentsCount, int? repostsCount, bool? isLiked,
    bool? isSaved, bool? isReposted, bool? isPinned, String? status, bool? isPublic,
    String? communityId, int? views,
  }) {
    return NetworkPost(
      id: id ?? this.id, userId: userId ?? this.userId, authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar, authorTitle: authorTitle ?? this.authorTitle,
      content: content ?? this.content, mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount, commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount, isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved, isReposted: isReposted ?? this.isReposted,
      isPinned: isPinned ?? this.isPinned, status: status ?? this.status, isPublic: isPublic ?? this.isPublic,
      communityId: communityId ?? this.communityId, views: views ?? this.views,
    );
  }

  String get formattedDate {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 7) return DateFormat('d MMM yyyy').format(createdAt);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inMinutes}min';
  }

  @override
  bool operator ==(Object other) => other is NetworkPost && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
