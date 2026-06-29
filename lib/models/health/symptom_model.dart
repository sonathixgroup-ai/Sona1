// 📁 lib/models/thix_sante/health/symptom_model.dart

class SymptomModel {
  final String id;
  final String patientId;
  final String nom;
  final int intensité; // 1 à 5
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomModel({
    required this.id,
    required this.patientId,
    required this.nom,
    required this.intensité,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    return SymptomModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      nom: json['nom'] ?? '',
      intensité: json['intensite'] ?? 3,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'nom': nom,
      'intensite': intensité,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SymptomModel copyWith({
    String? id,
    String? patientId,
    String? nom,
    int? intensité,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SymptomModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      nom: nom ?? this.nom,
      intensité: intensité ?? this.intensité,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper pour obtenir le libellé de l'intensité
  String get intensitéLabel {
    switch (intensité) {
      case 1: return 'Très léger';
      case 2: return 'Léger';
      case 3: return 'Modéré';
      case 4: return 'Fort';
      case 5: return 'Très fort';
      default: return 'Modéré';
    }
  }

  // Helper pour obtenir la couleur de l'intensité
  String get intensitéColor {
    switch (intensité) {
      case 1: return '#4CAF50';  // Vert
      case 2: return '#8BC34A';  // Vert clair
      case 3: return '#FF9800';  // Orange
      case 4: return '#FF5722';  // Orange foncé
      case 5: return '#F44336';  // Rouge
      default: return '#FF9800';
    }
  }
}
