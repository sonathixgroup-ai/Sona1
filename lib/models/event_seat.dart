// lib/models/event_seat.dart
enum SeatStatus { available, reserved, sold, selected }
enum SeatCategory { standard, vip, gold, family }

class EventSeat {
  final String id;
  final String eventId;
  final String row;
  final int number;
  final SeatCategory category;
  final double price;
  final SeatStatus status;
  final String? reservedBy;
  final DateTime? reservedUntil;
  final int? bookingId;

  EventSeat({
    required this.id,
    required this.eventId,
    required this.row,
    required this.number,
    required this.category,
    required this.price,
    required this.status,
    this.reservedBy,
    this.reservedUntil,
    this.bookingId,
  });

  factory EventSeat.fromJson(Map<String, dynamic> json) {
    return EventSeat(
      id: json['id'],
      eventId: json['event_id'],
      row: json['row'],
      number: json['number'],
      category: SeatCategory.values.firstWhere(
        (e) => e.toString() == 'SeatCategory.${json['category']}',
        orElse: () => SeatCategory.standard,
      ),
      price: (json['price'] ?? 0).toDouble(),
      status: SeatStatus.values.firstWhere(
        (e) => e.toString() == 'SeatStatus.${json['status']}',
        orElse: () => SeatStatus.available,
      ),
      reservedBy: json['reserved_by'],
      reservedUntil: json['reserved_until'] != null 
          ? DateTime.parse(json['reserved_until']) 
          : null,
      bookingId: json['booking_id'],
    );
  }

  String get displayName => '$row$number';
  String get categoryColor {
    switch (category) {
      case SeatCategory.standard: return '#4CAF50';
      case SeatCategory.vip: return '#FFD700';
      case SeatCategory.gold: return '#D4AF37';
      case SeatCategory.family: return '#2196F3';
    }
  }

  double get categoryPrice {
    switch (category) {
      case SeatCategory.standard: return price;
      case SeatCategory.vip: return price * 2;
      case SeatCategory.gold: return price * 3;
      case SeatCategory.family: return price * 1.5;
    }
  }

  bool get isAvailable => status == SeatStatus.available;
  bool get isReserved => status == SeatStatus.reserved;
  bool get isSold => status == SeatStatus.sold;
  bool get isSelected => status == SeatStatus.selected;
}

class SeatSelection {
  final String eventId;
  final List<EventSeat> selectedSeats;
  final double totalPrice;

  SeatSelection({
    required this.eventId,
    required this.selectedSeats,
    required this.totalPrice,
  });

  int get totalSeats => selectedSeats.length;
}
