// ------------------------------------------------------------------
// Fichier : models/module.dart
// Rôle : Module d'une formation. Une formation est composée de plusieurs
// modules ordonnés. Chaque module contient plusieurs leçons.
// ------------------------------------------------------------------

class Module {
  final String id;
  final String formationId;
  final String title;
  final String description;
  final int order; // ordre d'affichage dans la formation

  // Relations
  List<Lesson>? lessons;

  Module({
    required this.id,
    required this.formationId,
    required this.title,
    required this.description,
    required this.order,
    this.lessons,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'formation_id': formationId,
        'title': title,
        'description': description,
        'order': order,
      };

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        id: json['id'],
        formationId: json['formation_id'],
        title: json['title'],
        description: json['description'],
        order: json['order'],
      );

  Module copyWith({
    String? title,
    String? description,
    int? order,
    List<Lesson>? lessons,
  }) =>
      Module(
        id: id,
        formationId: formationId,
        title: title ?? this.title,
        description: description ?? this.description,
        order: order ?? this.order,
        lessons: lessons ?? this.lessons,
      );
}
