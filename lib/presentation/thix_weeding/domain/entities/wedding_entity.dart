// lib/presentation/thix_weeding/domain/entities/wedding_entity.dart
class WeddingEntity {
  final String id;
  final String locationName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String coupleNames;
  final String welcomeMessage;
  final String announcement;
  const WeddingEntity({
    required this.id,
    required this.locationName,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.coupleNames,
    required this.welcomeMessage,
    required this.announcement,
  });
}

class RsvpEntity {
  final String weddingId;
  final String guestName;
  final String status; // yes / no / maybe
  final int count;
  final String message;
  const RsvpEntity({
    required this.weddingId,
    required this.guestName,
    required this.status,
    required this.count,
    required this.message,
  });
}

class GiftItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double contributed;
  bool get isReserved => remaining <= 0;
  double get remaining => price - contributed;
  double get percent => price == 0 ? 0 : (contributed / price).clamp(0, 1);
  const GiftItem({required this.id, required this.name, required this.imageUrl, required this.price, this.contributed = 0});
}
