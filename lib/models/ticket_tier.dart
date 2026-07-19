// lib/models/ticket_tier.dart
class TicketTier {
  final String name;
  final double price;
  final int capacity;
  final int? remaining; // 🟢 Le champ manquant pour savoir combien il en reste !

  TicketTier({
    required this.name,
    required this.price,
    required this.capacity,
    this.remaining, // 🟢 Ajout au constructeur
  });

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    return TicketTier(
      name: json['name'] ?? 'Standard',
      price: (json['price'] ?? 0).toDouble(),
      capacity: json['capacity'] ?? 0,
      remaining: json['remaining'], // 🟢 Lecture depuis Supabase
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'capacity': capacity,
      if (remaining != null) 'remaining': remaining, // 🟢 Envoi vers Supabase
    };
  }
}
