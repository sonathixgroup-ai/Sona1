// lib/presentation/mon_pays/models/provincial_achievement.dart

class ProvincialAchievement {
  final String id;
  final String provinceId;
  final String title;
  final String description;
  final String category;
  final DateTime achievementDate;
  final String? imageUrl;

  ProvincialAchievement({
    required this.id,
    required this.provinceId,
    required this.title,
    required this.description,
    required this.category,
    required this.achievementDate,
    this.imageUrl,
  });

  factory ProvincialAchievement.fromJson(Map<String, dynamic> json) {
    return ProvincialAchievement(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      achievementDate: DateTime.parse(json['achievement_date'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'province_id': provinceId,
      'title': title,
      'description': description,
      'category': category,
      'achievement_date': achievementDate.toIso8601String().split('T')[0],
      'image_url': imageUrl,
    };
  }
}
