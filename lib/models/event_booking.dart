// lib/models/event_booking.dart

class EventBooking {
  final String id;
  final String eventId;
  final String userId;
  final int ticketQuantity;
  final double totalPrice;
  final String? paymentMethod;
  final String paymentStatus;
  final String ticketCode;
  final String qrCode;
  final String status;
  final DateTime bookingDate;

  // Champs additionnels venant de la jointure avec la table 'events'
  final String eventTitle;
  final String? eventImageUrl;
  final DateTime eventDate;
  final String eventLocation;

  EventBooking({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketQuantity,
    required this.totalPrice,
    this.paymentMethod,
    required this.paymentStatus,
    required this.ticketCode,
    required this.qrCode,
    required this.status,
    required this.bookingDate,
    this.eventTitle = '',
    this.eventImageUrl,
    required this.eventDate,
    this.eventLocation = '',
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    return EventBooking(
      id: json['id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      ticketQuantity: int.tryParse(json['ticket_quantity']?.toString() ?? '1') ?? 1,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'paid',
      ticketCode: json['ticket_code']?.toString() ?? '',
      qrCode: json['qr_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'confirmed',
      bookingDate: json['booking_date'] != null 
          ? DateTime.tryParse(json['booking_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      
      // Ces champs sont injectés par le service lors du getMyTickets
      eventTitle: json['event_title']?.toString() ?? 'Événement',
      eventImageUrl: json['event_image_url']?.toString(),
      eventDate: json['event_date'] != null 
          ? DateTime.tryParse(json['event_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventLocation: json['event_location']?.toString() ?? 'Lieu inconnu',
    );
  }
}
