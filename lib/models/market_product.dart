class MarketProduct {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? currency;
  final int price;
  final int? oldPrice;
  final int discountPercent;
  final double rating;
  final int ratingCount;
  final bool isFlash;
  final String? categoryId;
  final String? storeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.discountPercent,
    required this.rating,
    required this.ratingCount,
    required this.isFlash,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imageUrl,
    this.currency,
    this.oldPrice,
    this.categoryId,
    this.storeId,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic v) => v is DateTime ? v : DateTime.tryParse((v ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return MarketProduct(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      currency: (json['currency'] ?? 'XOF')?.toString(),
      price: (json['price'] as num?)?.toInt() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toInt(),
      discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isFlash: json['is_flash'] == true,
      categoryId: json['category_id']?.toString(),
      storeId: json['store_id']?.toString(),
      createdAt: parseDt(json['created_at']),
      updatedAt: parseDt(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'currency': currency,
        'price': price,
        'old_price': oldPrice,
        'discount_percent': discountPercent,
        'rating': rating,
        'rating_count': ratingCount,
        'is_flash': isFlash,
        'category_id': categoryId,
        'store_id': storeId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MarketProduct copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? currency,
    int? price,
    int? oldPrice,
    int? discountPercent,
    double? rating,
    int? ratingCount,
    bool? isFlash,
    String? categoryId,
    String? storeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MarketProduct(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        currency: currency ?? this.currency,
        price: price ?? this.price,
        oldPrice: oldPrice ?? this.oldPrice,
        discountPercent: discountPercent ?? this.discountPercent,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        isFlash: isFlash ?? this.isFlash,
        categoryId: categoryId ?? this.categoryId,
        storeId: storeId ?? this.storeId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
