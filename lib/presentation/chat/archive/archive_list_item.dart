// lib/presentation/chat/archive/search_filters.dart
// Modèle de données pour les filtres de recherche

class SearchFilters {
  final String? text;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? contactName;
  final String? messageType; // text, image, video, audio

  SearchFilters({
    this.text,
    this.startDate,
    this.endDate,
    this.contactName,
    this.messageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'contact_name': contactName,
      'message_type': messageType,
    };
  }
}
