// 📁 lib/models/thix_sante/health/constant_model.dart

class ConstantModel {
  final String id;
  final String patientId;
  final DateTime date;
  final double? tensionSystolic;
  final double? tensionDiastolic;
  final double? glycemie;
  final double? poids;
  final double? taille;
  final int? heartRate;
  final double? temperature;
  final double? spo2;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConstantModel({
    required this.id,
    required this.patientId,
    required this.date,
    this.tensionSystolic,
    this.tensionDiastolic,
    this.glycemie,
    this.poids,
    this.taille,
    this.heartRate,
    this.temperature,
    this.spo2,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConstantModel.fromJson(Map<String, dynamic> json) {
    return ConstantModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      tensionSystolic: json['tension_systolic']?.toDouble(),
      tensionDiastolic: json['tension_diastolic']?.toDouble(),
      glycemie: json['glycemie']?.toDouble(),
      poids: json['poids']?.toDouble(),
      taille: json['taille']?.toDouble(),
      heartRate: json['heart_rate'],
      temperature: json['temperature']?.toDouble(),
      spo2: json['spo2']?.toDouble(),
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'date': date.toIso8601String(),
      'tension_systolic': tensionSystolic,
      'tension_diastolic': tensionDiastolic,
      'glycemie': glycemie,
      'poids': poids,
      'taille': taille,
      'heart_rate': heartRate,
      'temperature': temperature,
      'spo2': spo2,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConstantModel copyWith({
    String? id,
    String? patientId,
    DateTime? date,
    double? tensionSystolic,
    double? tensionDiastolic,
    double? glycemie,
    double? poids,
    double? taille,
    int? heartRate,
    double? temperature,
    double? spo2,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConstantModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      tensionSystolic: tensionSystolic ?? this.tensionSystolic,
      tensionDiastolic: tensionDiastolic ?? this.tensionDiastolic,
      glycemie: glycemie ?? this.glycemie,
      poids: poids ?? this.poids,
      taille: taille ?? this.taille,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      spo2: spo2 ?? this.spo2,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helpers pour vérifier si les valeurs sont normales
  bool isTensionNormale() {
    if (tensionSystolic == null || tensionDiastolic == null) return true;
    return tensionSystolic! < 130 && tensionDiastolic! < 85;
  }

  bool isGlycemieNormale() {
    if (glycemie == null) return true;
    return glycemie! >= 0.7 && glycemie! <= 1.10;
  }

  bool isPoidsNormal() {
    // Sans taille, on ne peut pas calculer l'IMC
    if (poids == null || taille == null) return true;
    final imc = poids! / ((taille! / 100) * (taille! / 100));
    return imc >= 18.5 && imc <= 25;
  }

  double? get imc {
    if (poids == null || taille == null) return null;
    return poids! / ((taille! / 100) * (taille! / 100));
  }

  String get tensionLabel {
    if (tensionSystolic == null || tensionDiastolic == null) return 'Non renseignée';
    if (tensionSystolic! < 130 && tensionDiastolic! < 85) return 'Normale';
    if (tensionSystolic! < 140 || tensionDiastolic! < 90) return 'Normale haute';
    if (tensionSystolic! < 160 || tensionDiastolic! < 100) return 'Hypertension stade 1';
    return 'Hypertension stade 2';
  }
}
