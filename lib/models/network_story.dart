// lib/models/network_story.dart
import 'package:flutter/material.dart';

class NetworkStory {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userTitle;
  final String imageUrl;
  final int duration; // en secondes
  final bool isActive;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;

  NetworkStory({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.userTitle,
    required this.imageUrl,
    required this.duration,
    required this.isActive,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
  });

  // Constructeur vide pour les tests
  NetworkStory.empty()
      : id = '',
        userId = '',
        userName = '',
        userAvatar = null,
        userTitle = '',
        imageUrl = '',
        duration = 24,
        isActive = true,
        createdAt = DateTime.now(),
        expiresAt = DateTime.now().add(const Duration(hours: 24)),
        isViewed = false;

  // Constructeur statique pour créer une nouvelle story
  static NetworkStory create({
    required String userId,
    required String userName,
    required String imageUrl,
    String? userAvatar,
    String? userTitle,
    int durationHours = 24,
  }) {
    final now = DateTime.now();
    return NetworkStory(
      id: '',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      userTitle: userTitle ?? 'Membre THIX',
      imageUrl: imageUrl,
      duration: durationHours,
      isActive: true,
      createdAt: now,
      expiresAt: now.add(Duration(hours: durationHours)),
    );
  }

  // Getters de base
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isCurrentUser => userId == _currentUserId;
  bool get hasUserAvatar => userAvatar != null && userAvatar!.isNotEmpty;
  bool get isValid => id.isNotEmpty && userId.isNotEmpty && imageUrl.isNotEmpty;
  bool get isAboutToExpire => expiresAt.difference(DateTime.now()).inHours < 6;
  
  String get avatarUrl => hasUserAvatar ? userAvatar! : '';
  String get userInitial => userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  
  double get remainingPercentage {
    final totalDuration = expiresAt.difference(createdAt).inSeconds;
    final elapsed = DateTime.now().difference(createdAt).inSeconds;
    return 1 - (elapsed / totalDuration).clamp(0.0, 1.0);
  }
  
  // Formatage du temps
  String get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inHours > 0) return '${remaining.inHours}h';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes}min';
    return 'bientôt expirée';
  }
  
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return 'le ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
  
  String get formattedExpiry => 'Expire le ${_formatDate(expiresAt)}';
  String get formattedCreation => 'Publiée le ${_formatDate(createdAt)}';
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Statistiques
  String get viewStatus {
    if (isViewed) return 'Déjà vue';
    if (isExpired) return 'Expirée';
    return 'Non vue';
  }
  
  Color get statusColor {
    if (isViewed) return Colors.grey;
    if (isExpired) return Colors.red;
    return Colors.green;
  }

  static String? _currentUserId;
  static void setCurrentUserId(String userId) => _currentUserId = userId;
  static void clearCurrentUserId() => _currentUserId = null;

  factory NetworkStory.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    
    return NetworkStory(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['display_name']?.toString() ?? 'Utilisateur',
      userAvatar: profiles?['avatar_url']?.toString(),
      userTitle: profiles?['title']?.toString() ?? 'Membre THIX',
      imageUrl: json['image_url']?.toString() ?? '',
      duration: (json['duration'] as int?) ?? 24,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : DateTime.now().add(const Duration(hours: 24)),
      isViewed: (json['is_viewed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'image_url': imageUrl,
    'duration': duration,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };

  NetworkStory copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? userTitle,
    String? imageUrl,
    int? duration,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isViewed,
  }) {
    return NetworkStory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userTitle: userTitle ?? this.userTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  NetworkStory markAsViewed() => copyWith(isViewed: true);

  @override
  String toString() => 'NetworkStory(id: $id, user: $userName, expired: $isExpired)';
}

// Extension pour les listes de stories
extension NetworkStoryListExtension on List<NetworkStory> {
  List<NetworkStory> get active => where((s) => s.isActive && !s.isExpired).toList();
  List<NetworkStory> get expired => where((s) => s.isExpired).toList();
  List<NetworkStory> get unviewed => where((s) => !s.isViewed).toList();
  List<NetworkStory> get currentUserStories => where((s) => s.isCurrentUser).toList();
  List<NetworkStory> get otherUserStories => where((s) => !s.isCurrentUser).toList();
  
  List<NetworkStory> get sortedByNewest => toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  List<NetworkStory> get sortedByExpiry => toList()
    ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
  
  Map<String, List<NetworkStory>> groupByUser() {
    final map = <String, List<NetworkStory>>{};
    for (final story in this) {
      map.putIfAbsent(story.userId, () => []).add(story);
    }
    return map;
  }
}
