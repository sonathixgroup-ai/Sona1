// lib/presentation/network/models/story_model.dart

class StoryModel {
  final String id;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String mediaUrl;
  final DateTime createdAt;

  StoryModel({required this.id, required this.userId, required this.displayName, required this.avatarUrl, required this.mediaUrl, required this.createdAt});

  factory StoryModel.fromMap(Map<String, dynamic> m) => StoryModel(
        id: m['id'] as String? ?? '',
        userId: m['author'] as String? ?? '',
        displayName: (m['profiles'] as Map?)?['display_name'] as String? ?? 'Utilisateur',
        avatarUrl: (m['profiles'] as Map?)?['photo_url'] as String? ?? '',
        mediaUrl: m['storage_path'] as String? ?? '',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
