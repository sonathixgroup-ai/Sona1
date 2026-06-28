class MarketCategory {
  final String id;
  final String title;
  final String? iconKey;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketCategory({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.iconKey,
  });

  factory MarketCategory.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) => v is DateTime ? v : DateTime.tryParse((v ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return MarketCategory(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      iconKey: json['icon_key']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: parseDt(json['created_at']),
      updatedAt: parseDt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon_key': iconKey,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MarketCategory copyWith({
    String? id,
    String? title,
    String? iconKey,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MarketCategory(
        id: id ?? this.id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
