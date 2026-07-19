class TicketTier {
  final String name;
  final double price;
  final int capacity;

  TicketTier({
    required this.name,
    required this.price,
    required this.capacity,
  });

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    return TicketTier(
      name: json['name'] ?? 'Standard',
      price: (json['price'] ?? 0).toDouble(),
      capacity: json['capacity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'capacity': capacity,
    };
  }
}
