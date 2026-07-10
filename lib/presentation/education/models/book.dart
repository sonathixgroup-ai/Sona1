class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? fileUrl;
  final String? category;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.price = 0.0,
    this.imageUrl,
    this.fileUrl,
    this.category,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'],
    title: json['title'],
    author: json['author'],
    description: json['description'],
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['image_url'],
    fileUrl: json['file_url'],
    category: json['category'],
    createdBy: json['created_by'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'file_url': fileUrl,
    'category': category,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
