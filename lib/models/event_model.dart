// lib/models/event_model.dart
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
  final String city;
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
  final DateTime? updatedAt;

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
    required this.city,
    required this.price,
    required this.priceCurrency,
    required this.isFree,
    this.capacity,
    this.remainingTickets,
    required this.isFeatured,
    required this.status,
    this.organizerId,
    this.organizerName,
    this.contactPhone,
    this.contactEmail,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['sub_category'],
      imageUrl: json['image_url'],
      bannerUrl: json['banner_url'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      location: json['location'] ?? '',
      address: json['address'],
      city: json['city'] ?? '',
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (imageUrl != null) 'image_url': imageUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'location': location,
      if (address != null) 'address': address,
      'city': city,
      'price': price,
      'price_currency': priceCurrency,
      'is_free': isFree,
      if (capacity != null) 'capacity': capacity,
      if (remainingTickets != null) 'remaining_tickets': remainingTickets,
      'is_featured': isFeatured,
      'status': status,
      if (organizerId != null) 'organizer_id': organizerId,
      if (organizerName != null) 'organizer_name': organizerName,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (contactEmail != null) 'contact_email': contactEmail,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'shares_count': sharesCount,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
