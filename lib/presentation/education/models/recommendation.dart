// ------------------------------------------------------------------
// Fichier : models/recommendation.dart
// Rôle : Recommandation de formation pour un utilisateur, basée sur
// des algorithmes (par exemple, historique, préférences, etc.).
// ------------------------------------------------------------------

class Recommendation {
  final String id;
  final String userId;
  final String formationId;
  final double score; // score de pertinence
  final String reason; // texte explicatif

  // Relation
  Formation? formation;

  Recommendation({
    required this.id,
    required this.userId,
    required this.formationId,
    required this.score,
    required this.reason,
    this.formation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'formation_id': formationId,
        'score': score,
        'reason': reason,
      };

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: json['id'],
        userId: json['user_id'],
        formationId: json['formation_id'],
        score: (json['score'] as num).toDouble(),
        reason: json['reason'],
      );

  Recommendation copyWith({
    double? score,
    String? reason,
    Formation? formation,
  }) =>
      Recommendation(
        id: id,
        userId: userId,
        formationId: formationId,
        score: score ?? this.score,
        reason: reason ?? this.reason,
        formation: formation ?? this.formation,
      );
}
