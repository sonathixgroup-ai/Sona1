// models/question.dart
class Question {
  final String id;
  final String evaluationId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final DateTime? createdAt;

  Question({
    required this.id,
    required this.evaluationId,
    required this.question,
    this.options = const [],
    this.correctIndex = 0,
    this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        evaluationId: json['evaluation_id'],
        question: json['question'],
        options: List<String>.from(json['options'] ?? []),
        correctIndex: json['correct_index'] ?? 0,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'evaluation_id': evaluationId,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'created_at': createdAt?.toIso8601String(),
      };

  Question copyWith({
    String? question,
    List<String>? options,
    int? correctIndex,
  }) =>
      Question(
        id: id,
        evaluationId: evaluationId,
        question: question ?? this.question,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
        createdAt: createdAt,
      );
}
