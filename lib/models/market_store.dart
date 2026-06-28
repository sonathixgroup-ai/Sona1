class MarketStore {
  final String id;
  final String name;
  final String? coverImageUrl;
  final double rating;
  final int ratingCount;
  final String? city;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketStore({
    required this.id,
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
    this.city,
  });

  factory MarketStore.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) => v is DateTime ? v : DateTime.tryParse((v ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return MarketStore(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      city: json['city']?.toString(),
      createdAt: parseDt(json['created_at']),
      updatedAt: parseDt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cover_image_url': coverImageUrl,
        'rating': rating,
        'rating_count': ratingCount,
        'city': city,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MarketStore copyWith({
    String? id,
    String? name,
    String? coverImageUrl,
    double? rating,
    int? ratingCount,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MarketStore(
        id: id ?? this.id,
        name: name ?? this.name,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        city: city ?? this.city,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
