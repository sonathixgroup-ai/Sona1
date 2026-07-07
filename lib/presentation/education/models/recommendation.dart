import 'formation.dart';

class Recommendation {
  final String id;
  final String userId;
  final String formationId;
  final double score;
  final String? reason;
  final DateTime? createdAt;
  Formation? formation;

  Recommendation({
    required this.id,
    required this.userId,
    required this.formationId,
    this.score = 0.0,
    this.reason,
    this.createdAt,
    this.formation,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'],
        userId: json['user_id'],
        formationId: json['formation_id'],
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'],
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        formation: json['formation'] != null ? Formation.fromJson(json['formation']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'formation_id': formationId,
        'score': score,
        'reason': reason,
        'created_at': createdAt?.toIso8601String(),
        'formation': formation?.toJson(),
      };
}
