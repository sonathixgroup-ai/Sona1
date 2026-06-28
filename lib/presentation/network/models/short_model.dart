// lib/presentation/network/models/short_model.dart

class ShortModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final int views;

  ShortModel({required this.id, required this.title, required this.thumbnailUrl, required this.views});

  factory ShortModel.fromMap(Map<String, dynamic> m) => ShortModel(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        thumbnailUrl: m['thumbnail'] as String? ?? '',
        views: (m['views'] as int?) ?? 0,
      );
}
