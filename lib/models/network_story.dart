import 'package:flutter/material.dart';

class NetworkStory {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String userTitle;
  
  // Médias et contenu
  final String imageUrl; // Consolidé pour pointer vers 'media_url'
  final String? textContent; // <-- AJOUT POUR LES STORIES TEXTE
  final String mediaType;    // <-- AJOUT POUR DIFFÉRENCIER IMAGE/VIDEO/TEXT
  
  final int duration; // en heures (pour l'affichage/choix utilisateur)
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
    this.textContent,
    this.mediaType = 'image',
    required this.duration,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
  });

  // Construction depuis les données de création (avant persistance)
  factory NetworkStory.fromCreation({
    required String userId,
    required String userName,
    required String imageUrl,
    String? textContent,
    String mediaType = 'image',
    String? userAvatar,
    String? userTitle,
    int durationHours = 24,
  }) {
    final now = DateTime.now();
    return NetworkStory(
      id: '', // sera attribué par la base
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      userTitle: userTitle ?? 'Membre THIX',
      imageUrl: imageUrl,
      textContent: textContent,
      mediaType: mediaType,
      duration: durationHours,
      createdAt: now,
      expiresAt: now.add(Duration(hours: durationHours)),
    );
  }

  // Déserialisation depuis la réponse Supabase (vue active_stories ou jointure)
  factory NetworkStory.fromJson(Map<String, dynamic> json) {
    // Supporte à la fois l'ancienne jointure 'profiles' et les champs plats de la vue
    final profiles = json['profiles'] as Map<String, dynamic>?;
    
    return NetworkStory(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: profiles?['display_name']?.toString() 
                ?? json['user_name']?.toString() 
                ?? 'Utilisateur',
      userAvatar: profiles?['avatar_url']?.toString() 
                  ?? json['user_avatar']?.toString(),
      userTitle: profiles?['title']?.toString() 
                ?? json['user_title']?.toString() 
                ?? 'Membre THIX',
      
      // ⚠️ Gère la nouvelle colonne 'media_url' et retombe sur 'image_url' si besoin
      imageUrl: json['media_url']?.toString() ?? json['image_url']?.toString() ?? '',
      
      // ⚠️ Ajout de la gestion du texte et du type de média
      textContent: json['text_content']?.toString(),
      mediaType: json['media_type']?.toString() ?? 'image',
      
      duration: (json['duration'] as int?) ?? 24, // heures
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
      isViewed: (json['is_viewed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'media_url': imageUrl,
    'text_content': textContent,
    'media_type': mediaType,
    'duration': duration,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };

  // Getters métier
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired;
  bool get hasUserAvatar => userAvatar != null && userAvatar!.isNotEmpty;
  String get avatarUrl => userAvatar ?? '';
  String get userInitial => userName.isNotEmpty ? userName[0].toUpperCase() : '?';

  double get remainingPercentage {
    final now = DateTime.now();
    final total = expiresAt.difference(createdAt).inSeconds;
    final elapsed = now.difference(createdAt).inSeconds;
    return (1 - elapsed / total).clamp(0.0, 1.0);
  }

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
  String _formatDate(DateTime date) =>
      '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

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

  // Méthode utilitaire pour marquer comme vue
  NetworkStory markAsViewed() => copyWith(isViewed: true);

  NetworkStory copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? userTitle,
    String? imageUrl,
    String? textContent,
    String? mediaType,
    int? duration,
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
      textContent: textContent ?? this.textContent,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  String toString() =>
      'NetworkStory(id: $id, user: $userName, type: $mediaType, expired: $isExpired)';
}

// Extension sur liste de stories
extension NetworkStoryListExtension on List<NetworkStory> {
  List<NetworkStory> get active => where((s) => !s.isExpired).toList();
  List<NetworkStory> get expired => where((s) => s.isExpired).toList();
  List<NetworkStory> get unviewed => where((s) => !s.isViewed).toList();
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
