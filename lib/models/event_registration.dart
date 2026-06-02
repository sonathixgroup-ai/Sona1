/// Modèle pour une inscription à un événement
class EventRegistration {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  EventRegistration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Crée une EventRegistration à partir d'un JSON
  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convertit EventRegistration en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Vérifie si l'inscription est confirmée
  bool get isConfirmed => status == 'confirmed';

  /// Vérifie si l'inscription est annulée
  bool get isCancelled => status == 'cancelled';

  /// Crée une copie avec modifications possibles
  EventRegistration copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'EventRegistration(id: $id, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRegistration &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
