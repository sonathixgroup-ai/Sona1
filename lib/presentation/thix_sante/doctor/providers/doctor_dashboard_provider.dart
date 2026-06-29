// 📁 lib/presentation/thix_sante/doctor/providers/doctor_dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/appointment_repository.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../../data/repositories/prescription_repository.dart';
import '../../../../core/utils/logger.dart';

// Repositories
final doctorAppointmentRepositoryProvider = Provider((ref) => AppointmentRepository());
final doctorPatientRepositoryProvider = Provider((ref) => PatientRepository());
final doctorPrescriptionRepositoryProvider = Provider((ref) => PrescriptionRepository());

// État du tableau de bord médecin
class DoctorDashboardState {
  final int patientCount;
  final int todayAppointmentsCount;
  final int pendingPrescriptionsCount;
  final int alertsCount;
  final List<Map<String, dynamic>> recentAlerts;
  final List<Map<String, dynamic>> pendingTeleexpertise;
  final bool isLoading;
  final String? error;

  DoctorDashboardState({
    this.patientCount = 0,
    this.todayAppointmentsCount = 0,
    this.pendingPrescriptionsCount = 0,
    this.alertsCount = 0,
    this.recentAlerts = const [],
    this.pendingTeleexpertise = const [],
    this.isLoading = false,
    this.error,
  });

  DoctorDashboardState copyWith({
    int? patientCount,
    int? todayAppointmentsCount,
    int? pendingPrescriptionsCount,
    int? alertsCount,
    List<Map<String, dynamic>>? recentAlerts,
    List<Map<String, dynamic>>? pendingTeleexpertise,
    bool? isLoading,
    String? error,
  }) {
    return DoctorDashboardState(
      patientCount: patientCount ?? this.patientCount,
      todayAppointmentsCount: todayAppointmentsCount ?? this.todayAppointmentsCount,
      pendingPrescriptionsCount: pendingPrescriptionsCount ?? this.pendingPrescriptionsCount,
      alertsCount: alertsCount ?? this.alertsCount,
      recentAlerts: recentAlerts ?? this.recentAlerts,
      pendingTeleexpertise: pendingTeleexpertise ?? this.pendingTeleexpertise,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final doctorDashboardProvider = StateNotifierProvider<DoctorDashboardNotifier, DoctorDashboardState>((ref) {
  return DoctorDashboardNotifier(ref);
});

class DoctorDashboardNotifier extends StateNotifier<DoctorDashboardState> {
  final Ref _ref;

  DoctorDashboardNotifier(this._ref) : super(DoctorDashboardState(isLoading: true)) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final patientRepo = _ref.read(doctorPatientRepositoryProvider);
      final appointmentRepo = _ref.read(doctorAppointmentRepositoryProvider);
      final prescriptionRepo = _ref.read(doctorPrescriptionRepositoryProvider);

      // Récupération des données
      final patients = await patientRepo.getPatients();
      final appointments = await appointmentRepo.getAppointments();
      final prescriptions = await prescriptionRepo.getPrescriptions();

      final today = DateTime.now();
      final todayAppointments = appointments.where((a) =>
        a.date.year == today.year &&
        a.date.month == today.month &&
        a.date.day == today.day
      ).toList();

      // Alertes simulées (à connecter à un vrai service)
      final alerts = [
        {'patientName': 'Julie Petit', 'message': 'Glycémie élevée (2.1 g/L)', 'severity': 'high'},
        {'patientName': 'Paul Moreau', 'message': 'Tension anormale (165/95)', 'severity': 'medium'},
      ];

      // Demandes de téléexpertise simulées
      final teleexpertise = [
        {'patientName': 'Emma Dubois', 'description': 'Éruption cutanée sur le bras', 'date': '17/12/2024'},
      ];

      state = DoctorDashboardState(
        patientCount: patients.length,
        todayAppointmentsCount: todayAppointments.length,
        pendingPrescriptionsCount: prescriptions.where((p) => p.status == 'pending').length,
        alertsCount: alerts.length,
        recentAlerts: alerts,
        pendingTeleexpertise: teleexpertise,
        isLoading: false,
      );
    } catch (e, st) {
      Logger.error('Erreur chargement dashboard médecin', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }

  // Marquer une alerte comme traitée
  Future<bool> markAlertAsResolved(String patientName) async {
    try {
      // Logique à implémenter avec un service d'alertes
      final currentAlerts = List<Map<String, dynamic>>.from(state.recentAlerts);
      final updatedAlerts = currentAlerts.where((a) => a['patientName'] != patientName).toList();
      state = state.copyWith(
        recentAlerts: updatedAlerts,
        alertsCount: updatedAlerts.length,
      );
      return true;
    } catch (e) {
      Logger.error('Erreur résolution alerte', error: e);
      return false;
    }
  }

  // Répondre à une demande de téléexpertise
  Future<bool> respondTeleexpertise(String patientName, bool accept) async {
    try {
      final currentRequests = List<Map<String, dynamic>>.from(state.pendingTeleexpertise);
      final updatedRequests = currentRequests.where((r) => r['patientName'] != patientName).toList();
      state = state.copyWith(pendingTeleexpertise: updatedRequests);
      return true;
    } catch (e) {
      Logger.error('Erreur réponse téléexpertise', error: e);
      return false;
    }
  }
}
