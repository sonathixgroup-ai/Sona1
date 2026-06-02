/// Modèle pour représenter un élément d'événement
class EventItem {
  final String id;
  final String title;
  final String description;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final int? maxParticipants;
  final int? currentParticipants;
  final bool? isActive;
  final String? imageUrl;
  final String? imageAssetPath;
  final double? price;
  final DateTime? startsAt;
  final String? priceLabel;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.startDate,
    this.endDate,
    this.location,
    this.maxParticipants,
    this.currentParticipants,
    this.isActive,
    this.imageUrl,
    this.imageAssetPath,
    this.price,
    this.startsAt,
    this.priceLabel,
  });

  /// Crée un EventItem à partir d'un JSON
  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sans titre',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      location: json['location'] as String? ?? '',
      maxParticipants: json['max_participants'] as int?,
      currentParticipants: json['current_participants'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      imageAssetPath: json['image_asset_path'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      priceLabel: json['price_label'] as String? ?? 'Gratuit',
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'].toString())
          : DateTime.now(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
    );
  }

  /// Convertit EventItem en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'is_active': isActive,
      'image_url': imageUrl,
      'image_asset_path': imageAssetPath,
      'price': price,
      'price_label': priceLabel,
      'starts_at': startsAt?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  /// Crée un EventItem placeholder pour les cas de chargement
  static EventItem placeholder({required String id}) {
    return EventItem(
      id: id,
      title: 'Événement $id',
      description: 'Chargement en cours...',
      category: 'Général',
      isActive: true,
      priceLabel: 'En attente',
      startsAt: DateTime.now(),
      location: 'À déterminer',
    );
  }

  /// Crée une copie avec modifications possibles
  EventItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    int? maxParticipants,
    int? currentParticipants,
    bool? isActive,
    String? imageUrl,
    String? imageAssetPath,
    double? price,
    DateTime? startsAt,
    String? priceLabel,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      price: price ?? this.price,
      startsAt: startsAt ?? this.startsAt,
      priceLabel: priceLabel ?? this.priceLabel,
    );
  }

  @override
  String toString() => 'EventItem(id: $id, title: $title, location: $location)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
