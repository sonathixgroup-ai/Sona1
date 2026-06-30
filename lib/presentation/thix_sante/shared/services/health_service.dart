// presentation/thix_sante/shared/services/health_service.dart
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

/// Service principal pour le module THIX Santé.
/// Gère les appels API, la persistance et la logique métier.
class HealthService {
  // Singleton
  HealthService._internal();
  static final HealthService _instance = HealthService._internal();
  static HealthService get instance => _instance;

  // Ici, vous pouvez injecter un client HTTP, un repository, etc.
  // Exemple : final SupabaseClient _supabase = ...

  // ============================================================
  // RÉSUMÉ DE SANTÉ
  // ============================================================

  /// Récupère le résumé de santé pour un patient donné.
  Future<HealthSummary> fetchHealthSummary(String patientId) async {
    // À implémenter : appeler l'API ou Supabase
    // Pour l'instant, retourner des données mockées
    await Future.delayed(const Duration(milliseconds: 500));
    return HealthSummary(
      consultationsThisYear: 12,
      examsCompleted: 7,
      activeMedications: 3,
      upcomingAppointments: 2,
      healthScore: 85,
      lastUpdate: DateTime.now(),
      upcomingAppointmentsList: await fetchAppointments(patientId, limit: 3),
      currentMedications: await fetchMedications(patientId, activeOnly: true),
      articles: await fetchHealthArticles(limit: 4),
    );
  }

  // ============================================================
  // RENDEZ-VOUS
  // ============================================================

  /// Récupère la liste des rendez-vous pour un patient.
  Future<List<Appointment>> fetchAppointments(
    String patientId, {
    int? limit,
    AppointmentStatus? status,
  }) async {
    // À implémenter
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Appointment(
        id: 'appt1',
        doctorId: 'doc1',
        doctorName: 'Dr. Dupont',
        doctorSpecialty: 'Généraliste',
        patientId: patientId,
        patientName: 'Michel',
        date: DateTime.now().add(const Duration(days: 2, hours: 3)),
        type: AppointmentType.inPerson,
        status: AppointmentStatus.scheduled,
        notes: 'Consultation de suivi',
      ),
      Appointment(
        id: 'appt2',
        doctorId: 'doc2',
        doctorName: 'Dr. Martin',
        doctorSpecialty: 'Cardiologue',
        patientId: patientId,
        patientName: 'Michel',
        date: DateTime.now().add(const Duration(days: 7, hours: 10)),
        type: AppointmentType.teleconsultation,
        status: AppointmentStatus.confirmed,
        notes: 'Téléconsultation',
        teleconsultationLink: 'https://meet.jit.si/consultation123',
      ),
    ].where((a) => status == null || a.status == status).take(limit ?? 10).toList();
  }

  /// Récupère les rendez-vous à venir pour un patient.
  Future<List<Appointment>> fetchUpcomingAppointments(String patientId) async {
    final all = await fetchAppointments(patientId);
    return all.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed).toList();
  }

  /// Crée un nouveau rendez-vous.
  Future<Appointment> createAppointment(Appointment appointment) async {
    // À implémenter : envoyer à l'API
    await Future.delayed(const Duration(milliseconds: 400));
    // Simuler la création
    return appointment;
  }

  /// Annule un rendez-vous.
  Future<void> cancelAppointment(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Logique d'annulation
  }

  // ============================================================
  // MÉDICAMENTS
  // ============================================================

  /// Récupère les médicaments d'un patient.
  Future<List<Medication>> fetchMedications(
    String patientId, {
    bool activeOnly = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Medication(
        id: 'med1',
        name: 'Paracétamol',
        dosage: '500 mg',
        frequency: '3 fois par jour',
        instructions: 'Prendre après les repas',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
        prescriptionId: 'presc1',
        prescribedBy: 'Dr. Dupont',
        reminders: [
          MedicationReminder(
            id: 'rem1',
            medicationId: 'med1',
            time: const TimeOfDay(hour: 8, minute: 0),
          ),
          MedicationReminder(
            id: 'rem2',
            medicationId: 'med1',
            time: const TimeOfDay(hour: 14, minute: 0),
          ),
          MedicationReminder(
            id: 'rem3',
            medicationId: 'med1',
            time: const TimeOfDay(hour: 20, minute: 0),
          ),
        ],
      ),
      Medication(
        id: 'med2',
        name: 'Amoxicilline',
        dosage: '250 mg',
        frequency: '2 fois par jour',
        instructions: 'Prendre avec un verre d\'eau',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
        prescriptionId: 'presc2',
        prescribedBy: 'Dr. Martin',
        reminders: [
          MedicationReminder(
            id: 'rem4',
            medicationId: 'med2',
            time: const TimeOfDay(hour: 9, minute: 0),
          ),
          MedicationReminder(
            id: 'rem5',
            medicationId: 'med2',
            time: const TimeOfDay(hour: 21, minute: 0),
          ),
        ],
      ),
    ].where((m) => !activeOnly || m.isActive).toList();
  }

  /// Ajoute un nouveau médicament.
  Future<Medication> addMedication(Medication medication) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return medication;
  }

  /// Met à jour un médicament (ex: marquer comme terminé).
  Future<Medication> updateMedication(Medication medication) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return medication;
  }

  // ============================================================
  // SYMPTÔMES
  // ============================================================

  /// Récupère l'historique des symptômes d'un patient.
  Future<List<Symptom>> fetchSymptoms(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Symptom(
        id: 'sym1',
        name: 'Maux de tête',
        intensity: 3,
        date: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Soulagé par le repos',
        triggers: ['Stress', 'Fatigue'],
        relievers: ['Paracétamol'],
        location: 'Front',
        duration: const Duration(hours: 2),
      ),
      Symptom(
        id: 'sym2',
        name: 'Douleur dos',
        intensity: 2,
        date: DateTime.now().subtract(const Duration(days: 3)),
        notes: 'Après une longue station assise',
        triggers: ['Posture'],
        location: 'Bas du dos',
      ),
    ];
  }

  /// Ajoute un nouveau symptôme.
  Future<Symptom> addSymptom(Symptom symptom) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return symptom;
  }

  // ============================================================
  // CONSTANTES VITALES
  // ============================================================

  /// Récupère les constantes vitales d'un patient.
  Future<List<VitalSign>> fetchVitalSigns(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      VitalSign(
        id: 'vit1',
        patientId: patientId,
        type: VitalType.weight,
        value: 72.5,
        unit: 'kg',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      VitalSign(
        id: 'vit2',
        patientId: patientId,
        type: VitalType.heartRate,
        value: 72,
        unit: 'bpm',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      VitalSign(
        id: 'vit3',
        patientId: patientId,
        type: VitalType.bloodPressureSystolic,
        value: 120,
        unit: 'mmHg',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      VitalSign(
        id: 'vit4',
        patientId: patientId,
        type: VitalType.bloodPressureDiastolic,
        value: 80,
        unit: 'mmHg',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Ajoute une constante vitale.
  Future<VitalSign> addVitalSign(VitalSign vital) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return vital;
  }

  // ============================================================
  // ORDONNANCES
  // ============================================================

  /// Récupère les ordonnances d'un patient.
  Future<List<Prescription>> fetchPrescriptions(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Prescription(
        id: 'presc1',
        patientId: patientId,
        patientName: 'Michel',
        doctorId: 'doc1',
        doctorName: 'Dr. Dupont',
        date: DateTime.now().subtract(const Duration(days: 10)),
        validUntil: DateTime.now().add(const Duration(days: 20)),
        status: PrescriptionStatus.active,
        medications: await fetchMedications(patientId),
        notes: 'Traitement pour l\'infection',
      ),
    ];
  }

  /// Crée une nouvelle ordonnance (pour les médecins).
  Future<Prescription> createPrescription(Prescription prescription) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return prescription;
  }

  // ============================================================
  // EXAMENS
  // ============================================================

  /// Récupère les résultats d'examens d'un patient.
  Future<List<ExamResult>> fetchExamResults(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ExamResult(
        id: 'exam1',
        patientId: patientId,
        examName: 'Prise de sang',
        date: DateTime.now().subtract(const Duration(days: 5)),
        result: 'Normale',
        status: ExamStatus.completed,
        comments: 'Tout est dans les normes',
      ),
      ExamResult(
        id: 'exam2',
        patientId: patientId,
        examName: 'Échographie',
        date: DateTime.now().subtract(const Duration(days: 12)),
        status: ExamStatus.pending,
        comments: 'En attente des résultats',
      ),
    ];
  }

  // ============================================================
  // VACCINS
  // ============================================================

  /// Récupère le carnet de vaccination d'un patient.
  Future<List<Vaccine>> fetchVaccines(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Vaccine(
        id: 'vac1',
        patientId: patientId,
        name: 'COVID-19',
        dateAdministered: DateTime(2023, 10, 15),
        boosterDate: DateTime(2024, 10, 15),
        batchNumber: 'BN1234',
        administeredBy: 'Dr. Dupont',
      ),
      Vaccine(
        id: 'vac2',
        patientId: patientId,
        name: 'DTP',
        dateAdministered: DateTime(2023, 5, 20),
        batchNumber: 'BN5678',
        administeredBy: 'Dr. Martin',
      ),
    ];
  }

  /// Ajoute un vaccin.
  Future<Vaccine> addVaccine(Vaccine vaccine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return vaccine;
  }

  // ============================================================
  // ARTICLES DE SANTÉ
  // ============================================================

  /// Récupère des articles santé.
  Future<List<HealthArticle>> fetchHealthArticles({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      HealthArticle(
        id: 'art1',
        title: '5 conseils pour rester en bonne santé',
        subtitle: 'Astuces simples pour votre bien-être',
        readTime: 3,
        author: 'Dr. Sophie',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['Prévention', 'Bien-être'],
        content: 'Contenu de l\'article...',
      ),
      HealthArticle(
        id: 'art2',
        title: 'Alimentation équilibrée : les bases',
        subtitle: 'Les nutriments essentiels',
        readTime: 4,
        author: 'Nutritionniste',
        publishDate: DateTime.now().subtract(const Duration(days: 5)),
        tags: ['Nutrition'],
        content: 'Contenu de l\'article...',
      ),
    ];
  }

  // ============================================================
  // ALERTES SANITAIRES
  // ============================================================

  /// Récupère les alertes sanitaires pour un patient.
  Future<List<HealthAlert>> fetchHealthAlerts(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      HealthAlert(
        id: 'alert1',
        title: 'Épidémie de grippe',
        description: 'La grippe saisonnière est en hausse. Pensez à vous faire vacciner.',
        severity: AlertSeverity.warning,
        date: DateTime.now().subtract(const Duration(days: 1)),
        source: 'ARS',
      ),
      HealthAlert(
        id: 'alert2',
        title: 'Rappel vaccination COVID-19',
        description: 'Vous êtes éligible pour une dose de rappel.',
        severity: AlertSeverity.info,
        date: DateTime.now().subtract(const Duration(days: 3)),
        source: 'Assurance Maladie',
      ),
    ];
  }

  // ============================================================
  // PHARMACIES / HÔPITAUX
  // ============================================================

  /// Recherche des pharmacies proches (simulé).
  Future<List<Pharmacy>> findNearbyPharmacies(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      Pharmacy(
        id: 'phar1',
        name: 'Pharmacie Centrale',
        address: '1 Rue de la Santé',
        phone: '0123456789',
        latitude: lat + 0.001,
        longitude: lng + 0.001,
        isOpen: true,
      ),
      Pharmacy(
        id: 'phar2',
        name: 'Pharmacie du Parc',
        address: '10 Avenue des Fleurs',
        phone: '0987654321',
        latitude: lat - 0.002,
        longitude: lng - 0.002,
        isOpen: false,
      ),
    ];
  }
}
