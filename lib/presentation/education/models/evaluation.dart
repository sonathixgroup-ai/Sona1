// ------------------------------------------------------------------
// Fichier : models/evaluation.dart
// Rôle : Évaluation (quiz) associée à une leçon. Contient une liste
// de questions et un score de réussite.
// ------------------------------------------------------------------
import 'formation.dart';
class Evaluation {
  final String id;
  final String lessonId;
  final int passingScore; // score minimum pour valider (en pourcentage)

  // Relations
  List<Question>? questions;

  Evaluation({
    required this.id,
    required this.lessonId,
    required this.passingScore,
    this.questions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'passing_score': passingScore,
      };

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
        id: json['id'],
        lessonId: json['lesson_id'],
        passingScore: json['passing_score'],
      );

  Evaluation copyWith({
    int? passingScore,
    List<Question>? questions,
  }) =>
      Evaluation(
        id: id,
        lessonId: lessonId,
        passingScore: passingScore ?? this.passingScore,
        questions: questions ?? this.questions,
      );
}
