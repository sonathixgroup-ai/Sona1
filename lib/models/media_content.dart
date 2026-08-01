class MediaContent {
  final String id;
  final String title;
  final String? subtitle;
  final String type;
  final String? year;
  final String coverUrl;
  final String videoUrl;
  final int viewCount;
  final int likeCount; // NOUVEAU
  final int commentCount; // NOUVEAU
  final int? rankPosition;
  final bool isTrending;
  final bool isNewRelease;
  final bool isRecommended;
  final bool isPublished;
  final bool isFeedOnly; // NOUVEAU
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaContent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.year,
    required this.coverUrl,
    required this.videoUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.rankPosition,
    this.isTrending = false,
    this.isNewRelease = false,
    this.isRecommended = false,
    this.isPublished = true,
    this.isFeedOnly = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaContent.fromJson(Map<String, dynamic> json) {
    // 🛡️ ANTI-CRASH : Sécurité absolue pour la date de création
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = json['created_at'] != null && json['created_at'].toString().trim().isNotEmpty
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    // 🛡️ ANTI-CRASH : Sécurité absolue pour la date de mise à jour
    DateTime parsedUpdatedAt;
    try {
      parsedUpdatedAt = json['updated_at'] != null && json['updated_at'].toString().trim().isNotEmpty
          ? DateTime.parse(json['updated_at'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedUpdatedAt = DateTime.now();
    }

    return MediaContent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      type: json['type'] ?? '',
      year: json['year'],
      coverUrl: json['cover_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      rankPosition: json['rank_position'],
      isTrending: json['is_trending'] ?? false,
      isNewRelease: json['is_new_release'] ?? false,
      isRecommended: json['is_recommended'] ?? false,
      isPublished: json['is_published'] ?? true,
      isFeedOnly: json['is_feed_only'] ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'year': year,
        'cover_url': coverUrl,
        'video_url': videoUrl,
        'view_count': viewCount,
        'like_count': likeCount,
        'comment_count': commentCount,
        'rank_position': rankPosition,
        'is_trending': isTrending,
        'is_new_release': isNewRelease,
        'is_recommended': isRecommended,
        'is_published': isPublished,
        'is_feed_only': isFeedOnly,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MediaContent copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? type,
    String? year,
    String? coverUrl,
    String? videoUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? rankPosition,
    bool? isTrending,
    bool? isNewRelease,
    bool? isRecommended,
    bool? isPublished,
    bool? isFeedOnly,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaContent(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      rankPosition: rankPosition ?? this.rankPosition,
      isTrending: isTrending ?? this.isTrending,
      isNewRelease: isNewRelease ?? this.isNewRelease,
      isRecommended: isRecommended ?? this.isRecommended,
      isPublished: isPublished ?? this.isPublished,
      isFeedOnly: isFeedOnly ?? this.isFeedOnly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get rankDisplay => rankPosition != null ? '#$rankPosition' : '';
}
