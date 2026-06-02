import 'package:flutter/foundation.dart';

@immutable
class EventItem {
  final String id;

  final String title;
  final String description;
  final String category;
  final String location;

  final DateTime startsAt;
  final DateTime? endsAt;

  final double price;

  final bool isRecommended;
  final bool isPublished;

  final String? imageAssetPath;

  final String? coverImageBucket;
  final String? coverImagePath;

  final String? organizerId;
  final String? organizerName;

  final int maxParticipants;
  final int registeredParticipants;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startsAt,
    required this.price,
    required this.isRecommended,
    required this.isPublished,
    required this.maxParticipants,
    required this.registeredParticipants,
    required this.createdAt,
    this.endsAt,
    this.imageAssetPath,
    this.coverImageBucket,
    this.coverImagePath,
    this.organizerId,
    this.organizerName,
    this.updatedAt,
  });

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get isFree => price <= 0;

  bool get isPaid => price > 0;

  bool get isSoldOut =>
      maxParticipants > 0 &&
      registeredParticipants >= maxParticipants;

  bool get isUpcoming =>
      startsAt.isAfter(DateTime.now());

  bool get hasStarted =>
      startsAt.isBefore(DateTime.now());

  int get remainingSeats {
    if (maxParticipants <= 0) {
      return 0;
    }

    return maxParticipants -
        registeredParticipants;
  }

  String get priceLabel {
    if (price <= 0) {
      return 'Gratuit';
    }

    return '${price.toStringAsFixed(0)} \$';
  }

  // ===========================================================================
  // JSON
  // ===========================================================================

  factory EventItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return EventItem(
      id: json['id']?.toString() ?? '',

      title:
          json['title']?.toString() ??
          'Sans titre',

      description:
          json['description']
                  ?.toString() ??
              '',

      category:
          json['category']
                  ?.toString() ??
              'Autre',

      location:
          json['location']
                  ?.toString() ??
              '',

      startsAt: DateTime.parse(
        json['event_date']
                ?.toString() ??
            DateTime.now()
                .toIso8601String(),
      ),

      endsAt:
          json['end_date'] != null
              ? DateTime.tryParse(
                  json['end_date']
                      .toString(),
                )
              : null,

      price: (json['price'] ?? 0)
          .toDouble(),

      isRecommended:
          json['is_recommended'] ==
              true,

      isPublished:
          json['is_published'] !=
              false,

      imageAssetPath:
          json['image_asset_path']
              ?.toString(),

      coverImageBucket:
          json['cover_image_bucket']
              ?.toString(),

      coverImagePath:
          json['cover_image_path']
              ?.toString(),

      organizerId:
          json['organizer_id']
              ?.toString(),

      organizerName:
          json['organizer_name']
              ?.toString(),

      maxParticipants:
          json['max_participants'] ??
              0,

      registeredParticipants:
          json['registered_participants'] ??
              0,

      createdAt: DateTime.parse(
        json['created_at']
                ?.toString() ??
            DateTime.now()
                .toIso8601String(),
      ),

      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(
                  json['updated_at']
                      .toString(),
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'event_date':
          startsAt.toIso8601String(),
      'end_date':
          endsAt?.toIso8601String(),
      'price': price,
      'is_recommended':
          isRecommended,
      'is_published':
          isPublished,
      'image_asset_path':
          imageAssetPath,
      'cover_image_bucket':
          coverImageBucket,
      'cover_image_path':
          coverImagePath,
      'organizer_id':
          organizerId,
      'organizer_name':
          organizerName,
      'max_participants':
          maxParticipants,
      'registered_participants':
          registeredParticipants,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String(),
    };
  }

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  EventItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? startsAt,
    DateTime? endsAt,
    double? price,
    bool? isRecommended,
    bool? isPublished,
    String? imageAssetPath,
    String? coverImageBucket,
    String? coverImagePath,
    String? organizerId,
    String? organizerName,
    int? maxParticipants,
    int? registeredParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          description ??
              this.description,
      category:
          category ?? this.category,
      location:
          location ?? this.location,
      startsAt:
          startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      price: price ?? this.price,
      isRecommended:
          isRecommended ??
              this.isRecommended,
      isPublished:
          isPublished ??
              this.isPublished,
      imageAssetPath:
          imageAssetPath ??
              this.imageAssetPath,
      coverImageBucket:
          coverImageBucket ??
              this.coverImageBucket,
      coverImagePath:
          coverImagePath ??
              this.coverImagePath,
      organizerId:
          organizerId ??
              this.organizerId,
      organizerName:
          organizerName ??
              this.organizerName,
      maxParticipants:
          maxParticipants ??
              this.maxParticipants,
      registeredParticipants:
          registeredParticipants ??
              this.registeredParticipants,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
