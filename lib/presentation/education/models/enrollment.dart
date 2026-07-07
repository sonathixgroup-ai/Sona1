// ------------------------------------------------------------------
// Fichier : models/enrollment.dart
// Rôle : Inscription d'un utilisateur à une formation. Suit la
// progression globale et le statut de l'inscription.
// ------------------------------------------------------------------
import 'formation.dart';
class Enrollment {
  final String id;
  final String userId;
  final String formationId;
  final String status; // 'in_progress', 'completed', 'cancelled'
  final double progress; // 0.0 à 1.0
  final DateTime startedAt;
  final DateTime? completedAt;

  // Relations
  Formation? formation;

  Enrollment({
    required this.id,
    required this.userId,
    required this.formationId,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.completedAt,
    this.formation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'formation_id': formationId,
        'status': status,
        'progress': progress,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'],
        userId: json['user_id'],
        formationId: json['formation_id'],
        status: json['status'],
        progress: (json['progress'] as num).toDouble(),
        startedAt: DateTime.parse(json['started_at']),
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'])
            : null,
      );

  Enrollment copyWith({
    String? status,
    double? progress,
    DateTime? completedAt,
    Formation? formation,
  }) =>
      Enrollment(
        id: id,
        userId: userId,
        formationId: formationId,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        formation: formation ?? this.formation,
      );
}
