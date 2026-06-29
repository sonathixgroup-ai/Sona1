// 📁 lib/presentation/thix_sante/doctor/providers/doctor_patient_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/user/patient_model.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../../core/utils/logger.dart';

final doctorPatientListRepositoryProvider = Provider((ref) => PatientRepository());

// État de la liste des patients
class DoctorPatientState {
  final List<PatientModel> patients;
  final List<PatientModel> filteredPatients;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  DoctorPatientState({
    this.patients = const [],
    this.filteredPatients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  DoctorPatientState copyWith({
    List<PatientModel>? patients,
    List<PatientModel>? filteredPatients,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return DoctorPatientState(
      patients: patients ?? this.patients,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final doctorPatientProvider = StateNotifierProvider<DoctorPatientNotifier, DoctorPatientState>((ref) {
  return DoctorPatientNotifier(ref);
});

class DoctorPatientNotifier extends StateNotifier<DoctorPatientState> {
  final Ref _ref;

  DoctorPatientNotifier(this._ref) : super(DoctorPatientState(isLoading: true)) {
    loadPatients();
  }

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(doctorPatientListRepositoryProvider);
      final patients = await repo.getPatients();
      state = DoctorPatientState(
        patients: patients,
        filteredPatients: patients,
        isLoading: false,
        searchQuery: '',
      );
    } catch (e, st) {
      Logger.error('Erreur chargement patients', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void searchPatients(String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      state = state.copyWith(
        filteredPatients: state.patients,
        searchQuery: '',
      );
      return;
    }

    final filtered = state.patients.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      p.email.toLowerCase().contains(lowerQuery) ||
      (p.phone?.contains(lowerQuery) ?? false)
    ).toList();

    state = state.copyWith(
      filteredPatients: filtered,
      searchQuery: query,
    );
  }

  Future<PatientModel?> getPatientDetail(String patientId) async {
    try {
      final repo = _ref.read(doctorPatientListRepositoryProvider);
      final patient = await repo.getPatientById(patientId);
      return patient;
    } catch (e) {
      Logger.error('Erreur chargement détails patient', error: e);
      return null;
    }
  }

  Future<bool> updatePatientNotes(String patientId, String notes) async {
    try {
      final repo = _ref.read(doctorPatientListRepositoryProvider);
      final success = await repo.updatePatientNotes(patientId, notes);
      if (success) {
        // Rafraîchir la liste
        await loadPatients();
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour notes patient', error: e);
      return false;
    }
  }
}
