// lib/models/event_model.dart
import 'package:intl/intl.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? subCategory;
  final String? imageUrl;
  final String? bannerUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? address;
  final String? city;
  final double price;
  final String priceCurrency;
  final bool isFree;
  final int? capacity;
  final int? remainingTickets;
  final bool isFeatured;
  final String status;
  final String? organizerId;
  final String? organizerName;
  final String? contactPhone;
  final String? contactEmail;
  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final DateTime createdAt;
  bool isLiked;
  bool isSaved;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subCategory,
    this.imageUrl,
    this.bannerUrl,
    required this.startDate,
    this.endDate,
    required this.location,
    this.address,
    this.city,
    this.price = 0,
    this.priceCurrency = 'FC',
    this.isFree = false,
    this.capacity,
    this.remainingTickets,
    this.isFeatured = false,
    this.status = 'upcoming',
    this.organizerId,
    this.organizerName,
    this.contactPhone,
    this.contactEmail,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      subCategory: json['sub_category'],
      imageUrl: json['image_url'],
      bannerUrl: json['banner_url'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'],
      address: json['address'],
      city: json['city'],
      price: (json['price'] ?? 0).toDouble(),
      priceCurrency: json['price_currency'] ?? 'FC',
      isFree: json['is_free'] ?? false,
      capacity: json['capacity'],
      remainingTickets: json['remaining_tickets'],
      isFeatured: json['is_featured'] ?? false,
      status: json['status'] ?? 'upcoming',
      organizerId: json['organizer_id'],
      organizerName: json['organizer_name'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'sub_category': subCategory,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'address': address,
      'city': city,
      'price': price,
      'price_currency': priceCurrency,
      'is_free': isFree,
      'capacity': capacity,
      'remaining_tickets': remainingTickets,
      'is_featured': isFeatured,
      'status': status,
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? subCategory,
    String? imageUrl,
    String? bannerUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? address,
    String? city,
    double? price,
    String? priceCurrency,
    bool? isFree,
    int? capacity,
    int? remainingTickets,
    bool? isFeatured,
    String? status,
    String? organizerId,
    String? organizerName,
    String? contactPhone,
    String? contactEmail,
    int? viewsCount,
    int? likesCount,
    int? sharesCount,
    DateTime? createdAt,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      price: price ?? this.price,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      isFree: isFree ?? this.isFree,
      capacity: capacity ?? this.capacity,
      remainingTickets: remainingTickets ?? this.remainingTickets,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // ============================================================
  // GETTERS UTILES
  // ============================================================

  String get formattedPrice {
    if (isFree) return 'Gratuit';
    return '${NumberFormat('#,###').format(price)} $priceCurrency';
  }

  String get formattedDate {
    final day = startDate.day.toString().padLeft(2, '0');
    final month = startDate.month.toString().padLeft(2, '0');
    final year = startDate.year;
    final hour = startDate.hour.toString().padLeft(2, '0');
    final minute = startDate.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • ${hour}h$minute';
  }

  String get shortDate {
    final day = startDate.day.toString().padLeft(2, '0');
    final month = startDate.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String get dayAndMonth {
    return DateFormat('dd MMM').format(startDate);
  }

  String get fullDate {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(startDate);
  }

  String get timeRange {
    if (endDate == null) {
      return DateFormat('HH:mm').format(startDate);
    }
    return '${DateFormat('HH:mm').format(startDate)} - ${DateFormat('HH:mm').format(endDate!)}';
  }

  String get categoryLabel {
    const labels = {
      'musique': 'Musique & Concerts',
      'conference': 'Conférences & Séminaires',
      'culture': 'Culture & Art',
      'sport': 'Sport & Loisirs',
      'festival': 'Festivals & Soirées',
      'spectacle': 'Spectacles',
      'exposition': 'Expositions',
    };
    return labels[category] ?? category;
  }

  String get categoryIcon {
    const icons = {
      'musique': '🎵',
      'conference': '🎤',
      'culture': '🎨',
      'sport': '⚽',
      'festival': '🎪',
      'spectacle': '🎭',
      'exposition': '🖼️',
    };
    return icons[category] ?? '📅';
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasAvailableTickets => (remainingTickets ?? 0) > 0;
  bool get isPastEvent => startDate.isBefore(DateTime.now());
}

// ============================================================
// MODÈLE BILLET (RÉSERVATION)
// ============================================================

class EventBooking {
  final String id;
  final String eventId;
  final String eventTitle;
  final String? eventImageUrl;
  final DateTime eventDate;
  final String eventLocation;
  final int ticketQuantity;
  final double totalPrice;
  final String paymentStatus;
  final String ticketCode;
  final String? qrCode;
  final String status;
  final DateTime bookingDate;

  EventBooking({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventImageUrl,
    required this.eventDate,
    required this.eventLocation,
    required this.ticketQuantity,
    required this.totalPrice,
    required this.paymentStatus,
    required this.ticketCode,
    this.qrCode,
    required this.status,
    required this.bookingDate,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    return EventBooking(
      id: json['id'],
      eventId: json['event_id'],
      eventTitle: json['event_title'] ?? '',
      eventImageUrl: json['event_image_url'],
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date']) 
          : DateTime.now(),
      eventLocation: json['event_location'] ?? '',
      ticketQuantity: json['ticket_quantity'] ?? 1,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      paymentStatus: json['payment_status'] ?? 'pending',
      ticketCode: json['ticket_code'] ?? '',
      qrCode: json['qr_code'],
      status: json['status'] ?? 'confirmed',
      bookingDate: DateTime.parse(json['booking_date']),
    );
  }

  String get formattedTotalPrice {
    return '${NumberFormat('#,###').format(totalPrice)} FC';
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isUsed => status == 'used';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => eventDate.isAfter(DateTime.now());
}

// ============================================================
// EXTENSIONS POUR LISTES
// ============================================================

extension EventListExtension on List<Event> {
  List<Event> get upcoming => where((e) => e.isUpcoming && !e.isPastEvent).toList();
  List<Event> get featured => where((e) => e.isFeatured).toList();
  List<Event> get free => where((e) => e.isFree).toList();
  List<Event> get paid => where((e) => !e.isFree).toList();
  
  List<Event> byCategory(String category) {
    return where((e) => e.category == category).toList();
  }
  
  List<Event> byCity(String city) {
    return where((e) => e.city == city).toList();
  }
  
  List<Event> thisWeek() {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    return where((e) => 
      e.startDate.isAfter(now) && e.startDate.isBefore(weekLater)
    ).toList();
  }
  
  List<Event> thisMonth() {
    final now = DateTime.now();
    return where((e) => 
      e.startDate.month == now.month && e.startDate.year == now.year
    ).toList();
  }
  
  Map<String, List<Event>> groupByCategory() {
    final map = <String, List<Event>>{};
    for (final event in this) {
      map.putIfAbsent(event.category, () => []).add(event);
    }
    return map;
  }
  
  Map<DateTime, List<Event>> groupByDate() {
    final map = <DateTime, List<Event>>{};
    for (final event in this) {
      final date = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      map.putIfAbsent(date, () => []).add(event);
    }
    return map;
  }
  
  int get totalViews => fold(0, (sum, e) => sum + e.viewsCount);
  int get totalLikes => fold(0, (sum, e) => sum + e.likesCount);
  double get averagePrice => isEmpty ? 0.0 : fold<double>(0.0, (sum, e) => sum + e.price) / length;
}
