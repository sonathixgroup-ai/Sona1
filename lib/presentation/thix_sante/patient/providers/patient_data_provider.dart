// 📁 lib/presentation/thix_sante/patient/providers/patient_data_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/user/patient_model.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../../core/utils/logger.dart';

final patientRepositoryProvider = Provider((ref) => PatientRepository());

class PatientDataState {
  final PatientModel? patient;
  final bool isLoading;
  final String? error;

  PatientDataState({this.patient, this.isLoading = false, this.error});
}

final patientDataProvider = StateNotifierProvider<PatientDataNotifier, PatientDataState>((ref) {
  return PatientDataNotifier(ref);
});

class PatientDataNotifier extends StateNotifier<PatientDataState> {
  final Ref _ref;

  PatientDataNotifier(this._ref) : super(PatientDataState(isLoading: true)) {
    loadPatientData();
  }

  Future<void> loadPatientData() async {
    state = PatientDataState(isLoading: true);
    try {
      final repo = _ref.read(patientRepositoryProvider);
      final patient = await repo.getCurrentPatient();
      state = PatientDataState(patient: patient, isLoading: false);
    } catch (e, st) {
      Logger.error('Erreur chargement données patient', error: e, stackTrace: st);
      state = PatientDataState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updatePatientData(PatientModel updatedPatient) async {
    state = PatientDataState(isLoading: true);
    try {
      final repo = _ref.read(patientRepositoryProvider);
      final success = await repo.updatePatient(updatedPatient);
      if (success) {
        state = PatientDataState(patient: updatedPatient, isLoading: false);
        return true;
      } else {
        state = PatientDataState(patient: state.patient, isLoading: false, error: 'Mise à jour échouée');
        return false;
      }
    } catch (e, st) {
      Logger.error('Erreur mise à jour patient', error: e, stackTrace: st);
      state = PatientDataState(patient: state.patient, isLoading: false, error: e.toString());
      return false;
    }
  }
}
