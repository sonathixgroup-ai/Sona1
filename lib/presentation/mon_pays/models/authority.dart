// lib/presentation/mon_pays/models/authority.dart
// Entité Autorité avec fromJson/toJson

class Authority {
  final String id;
  final String name;
  final String title;
  final String? imageUrl;
  final String biography;
  final String mandate;
  final String party;
  final List<String> speeches;
  final List<String> videos;
  final List<String> publications;
  final Map<String, String> socialNetworks;
  final List<Map<String, String>> agenda;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Authority({
    required this.id,
    required this.name,
    required this.title,
    this.imageUrl,
    required this.biography,
    required this.mandate,
    required this.party,
    this.speeches = const [],
    this.videos = const [],
    this.publications = const [],
    this.socialNetworks = const {},
    this.agenda = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Authority.fromJson(Map<String, dynamic> json) {
    return Authority(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
      biography: json['biography'] as String? ?? '',
      mandate: json['mandate'] as String? ?? '',
      party: json['party'] as String? ?? '',
      speeches: List<String>.from(json['speeches'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      publications: List<String>.from(json['publications'] ?? []),
      socialNetworks: Map<String, String>.from(json['social_networks'] ?? {}),
      agenda: (json['agenda'] as List?)
          ?.map((e) => Map<String, String>.from(e))
          .toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'image_url': imageUrl,
    'biography': biography,
    'mandate': mandate,
    'party': party,
    'speeches': speeches,
    'videos': videos,
    'publications': publications,
    'social_networks': socialNetworks,
    'agenda': agenda,
  };

  Authority copyWith({
    String? id,
    String? name,
    String? title,
    String? imageUrl,
    String? biography,
    String? mandate,
    String? party,
    List<String>? speeches,
    List<String>? videos,
    List<String>? publications,
    Map<String, String>? socialNetworks,
    List<Map<String, String>>? agenda,
  }) {
    return Authority(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      biography: biography ?? this.biography,
      mandate: mandate ?? this.mandate,
      party: party ?? this.party,
      speeches: speeches ?? this.speeches,
      videos: videos ?? this.videos,
      publications: publications ?? this.publications,
      socialNetworks: socialNetworks ?? this.socialNetworks,
      agenda: agenda ?? this.agenda,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
