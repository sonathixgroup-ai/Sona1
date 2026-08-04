// lib/presentation/thix_weeding/domain/entities/wedding_entity.dart
import 'package:flutter/foundation.dart';

@immutable
class WeddingEntity {
  final String id;
  final String brideName;
  final String groomName;
  final DateTime date;
  final String locationName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String coverImageUrl;
  final String welcomeMessage;
  final String announcement;
  final bool isGiftEnabled;
  final bool isGalleryEnabled;
  final DateTime createdAt;

  const WeddingEntity({
    required this.id,
    required this.brideName,
    required this.groomName,
    required this.date,
    required this.locationName,
    required this.locationAddress,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.coverImageUrl,
    required this.welcomeMessage,
    this.announcement = '',
    this.isGiftEnabled = true,
    this.isGalleryEnabled = true,
    required this.createdAt,
  });

  String get coupleNames => '$brideName & $groomName';
  bool get isPast => date.isBefore(DateTime.now());
  bool get hasAnnouncement => announcement.trim().isNotEmpty;

  WeddingEntity copyWith({
    String? announcement,
    bool? isGiftEnabled,
    bool? isGalleryEnabled,
  }) {
    return WeddingEntity(
      id: id,
      brideName: brideName,
      groomName: groomName,
      date: date,
      locationName: locationName,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      coverImageUrl: coverImageUrl,
      welcomeMessage: welcomeMessage,
      announcement: announcement ?? this.announcement,
      isGiftEnabled: isGiftEnabled ?? this.isGiftEnabled,
      isGalleryEnabled: isGalleryEnabled ?? this.isGalleryEnabled,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is WeddingEntity && other.id == id;
  @override
  int get hashCode => id.hashCode;
}
