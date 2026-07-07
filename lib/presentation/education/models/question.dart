// ------------------------------------------------------------------
// Fichier : models/question.dart
// Rôle : Question d'une évaluation. Peut être à choix multiples,
// vrai/faux ou ouverte. Les options sont stockées en JSON.
// ------------------------------------------------------------------

class Question {
  final String id;
  final String evaluationId;
  final String text;
  final String type; // 'mcq', 'true_false', 'open'
  final List<String> options; // pour les QCM
  final String? correctAnswer; // pour les QCM et Vrai/Faux

  Question({
    required this.id,
    required this.evaluationId,
    required this.text,
    required this.type,
    required this.options,
    this.correctAnswer,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'evaluation_id': evaluationId,
        'text': text,
        'type': type,
        'options': options,
        'correct_answer': correctAnswer,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        evaluationId: json['evaluation_id'],
        text: json['text'],
        type: json['type'],
        options: List<String>.from(json['options'] ?? []),
        correctAnswer: json['correct_answer'],
      );

  Question copyWith({
    String? text,
    List<String>? options,
    String? correctAnswer,
  }) =>
      Question(
        id: id,
        evaluationId: evaluationId,
        text: text ?? this.text,
        type: type,
        options: options ?? this.options,
        correctAnswer: correctAnswer ?? this.correctAnswer,
      );
}
