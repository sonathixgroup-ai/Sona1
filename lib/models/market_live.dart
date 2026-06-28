class MarketLive {
  final String id;
  final String title;
  final String? hostName;
  final String? coverImageUrl;
  final bool isLive;
  final int viewers;
  final DateTime startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketLive({
    required this.id,
    required this.title,
    required this.isLive,
    required this.viewers,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    this.hostName,
    this.coverImageUrl,
  });

  factory MarketLive.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) => v is DateTime ? v : DateTime.tryParse((v ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return MarketLive(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      hostName: json['host_name']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      isLive: json['is_live'] == true,
      viewers: (json['viewers'] as num?)?.toInt() ?? 0,
      startedAt: parseDt(json['started_at']),
      createdAt: parseDt(json['created_at']),
      updatedAt: parseDt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'host_name': hostName,
        'cover_image_url': coverImageUrl,
        'is_live': isLive,
        'viewers': viewers,
        'started_at': startedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MarketLive copyWith({
    String? id,
    String? title,
    String? hostName,
    String? coverImageUrl,
    bool? isLive,
    int? viewers,
    DateTime? startedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MarketLive(
        id: id ?? this.id,
        title: title ?? this.title,
        hostName: hostName ?? this.hostName,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        isLive: isLive ?? this.isLive,
        viewers: viewers ?? this.viewers,
        startedAt: startedAt ?? this.startedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
