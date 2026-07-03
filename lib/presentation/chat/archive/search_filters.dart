// lib/presentation/chat/archive/search_filters.dart

class SearchFilters {
  final String? query;
  final String? type;
  final String? dateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool hasMedia;

  SearchFilters({
    this.query,
    this.type,
    this.dateRange,
    this.startDate,
    this.endDate,
    this.hasMedia = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'type': type,
      'dateRange': dateRange,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'hasMedia': hasMedia,
    };
  }
}
