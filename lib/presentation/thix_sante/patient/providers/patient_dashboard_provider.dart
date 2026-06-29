// 📁 lib/presentation/thix_sante/patient/providers/patient_dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/symptom_repository.dart';
import '../../../../data/repositories/medication_repository.dart';
import '../../../../data/repositories/constant_repository.dart';
import '../../../../data/repositories/appointment_repository.dart';
import '../../../../core/utils/logger.dart';

// Repositories
final symptomRepositoryProvider = Provider((ref) => SymptomRepository());
final medicationRepositoryProvider = Provider((ref) => MedicationRepository());
final constantRepositoryProvider = Provider((ref) => ConstantRepository());
final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());

// État du dashboard
class DashboardState {
  final int symptomCount;
  final int activeMedicationCount;
  final int constantCount;
  final int upcomingAppointmentsCount;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.symptomCount = 0,
    this.activeMedicationCount = 0,
    this.constantCount = 0,
    this.upcomingAppointmentsCount = 0,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    int? symptomCount,
    int? activeMedicationCount,
    int? constantCount,
    int? upcomingAppointmentsCount,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      symptomCount: symptomCount ?? this.symptomCount,
      activeMedicationCount: activeMedicationCount ?? this.activeMedicationCount,
      constantCount: constantCount ?? this.constantCount,
      upcomingAppointmentsCount: upcomingAppointmentsCount ?? this.upcomingAppointmentsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final patientDashboardProvider = StateNotifierProvider<PatientDashboardNotifier, DashboardState>((ref) {
  return PatientDashboardNotifier(ref);
});

class PatientDashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  PatientDashboardNotifier(this._ref) : super(DashboardState(isLoading: true)) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final symptomRepo = _ref.read(symptomRepositoryProvider);
      final medicationRepo = _ref.read(medicationRepositoryProvider);
      final constantRepo = _ref.read(constantRepositoryProvider);
      final appointmentRepo = _ref.read(appointmentRepositoryProvider);

      final symptoms = await symptomRepo.getSymptoms();
      final medications = await medicationRepo.getMedications();
      final constants = await constantRepo.getConstants();
      final appointments = await appointmentRepo.getAppointments();

      final activeMeds = medications.where((m) => m.isActive).length;
      final upcoming = appointments.where((a) => a.date.isAfter(DateTime.now())).length;

      state = DashboardState(
        symptomCount: symptoms.length,
        activeMedicationCount: activeMeds,
        constantCount: constants.length,
        upcomingAppointmentsCount: upcoming,
        isLoading: false,
      );
    } catch (e, st) {
      Logger.error('Erreur chargement dashboard', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}
