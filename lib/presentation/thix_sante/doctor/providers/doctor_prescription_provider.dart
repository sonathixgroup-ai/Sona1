// 📁 lib/presentation/thix_sante/doctor/providers/doctor_prescription_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/prescription/prescription_model.dart';
import '../../../../data/repositories/prescription_repository.dart';
import '../../../../core/utils/logger.dart';

final doctorPrescriptionRepositoryProvider = Provider((ref) => PrescriptionRepository());

// État des prescriptions
class DoctorPrescriptionState {
  final List<PrescriptionModel> prescriptions;
  final Map<String, dynamic>? currentPrescription;
  final List<Map<String, String>> currentItems;
  final bool isLoading;
  final String? error;

  DoctorPrescriptionState({
    this.prescriptions = const [],
    this.currentPrescription,
    this.currentItems = const [],
    this.isLoading = false,
    this.error,
  });

  DoctorPrescriptionState copyWith({
    List<PrescriptionModel>? prescriptions,
    Map<String, dynamic>? currentPrescription,
    List<Map<String, String>>? currentItems,
    bool? isLoading,
    String? error,
  }) {
    return DoctorPrescriptionState(
      prescriptions: prescriptions ?? this.prescriptions,
      currentPrescription: currentPrescription ?? this.currentPrescription,
      currentItems: currentItems ?? this.currentItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final doctorPrescriptionProvider = StateNotifierProvider<DoctorPrescriptionNotifier, DoctorPrescriptionState>((ref) {
  return DoctorPrescriptionNotifier(ref);
});

class DoctorPrescriptionNotifier extends StateNotifier<DoctorPrescriptionState> {
  final Ref _ref;

  DoctorPrescriptionNotifier(this._ref) : super(DoctorPrescriptionState(isLoading: true)) {
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(doctorPrescriptionRepositoryProvider);
      final prescriptions = await repo.getPrescriptions();
      state = DoctorPrescriptionState(
        prescriptions: prescriptions,
        isLoading: false,
        currentItems: [],
      );
    } catch (e, st) {
      Logger.error('Erreur chargement prescriptions', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Ajouter un item à l'ordonnance en cours
  void addPrescriptionItem(Map<String, String> item) {
    final currentItems = List<Map<String, String>>.from(state.currentItems);
    currentItems.add(item);
    state = state.copyWith(currentItems: currentItems);
  }

  // Supprimer un item de l'ordonnance
  void removePrescriptionItem(int index) {
    final currentItems = List<Map<String, String>>.from(state.currentItems);
    currentItems.removeAt(index);
    state = state.copyWith(currentItems: currentItems);
  }

  // Vider l'ordonnance en cours
  void clearPrescription() {
    state = state.copyWith(currentItems: [], currentPrescription: null);
  }

  // Valider l'ordonnance
  Future<bool> validatePrescription({
    required String patientId,
    required String patientName,
    required List<Map<String, String>> items,
    String? doctorNotes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(doctorPrescriptionRepositoryProvider);

      // Créer l'ordonnance en base
      final prescription = PrescriptionModel(
        id: '',
        patientId: patientId,
        patientName: patientName,
        doctorId: 'current_doctor_id', // À connecter à l'auth
        items: items,
        status: 'pending',
        date: DateTime.now(),
        doctorNotes: doctorNotes,
      );

      final created = await repo.createPrescription(prescription);
      if (created != null) {
        // Ajouter à la liste
        final prescriptions = List<PrescriptionModel>.from(state.prescriptions);
        prescriptions.add(created);

        state = state.copyWith(
          prescriptions: prescriptions,
          currentItems: [],
          currentPrescription: null,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Erreur création ordonnance');
      return false;
    } catch (e, st) {
      Logger.error('Erreur validation prescription', error: e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Mettre à jour le statut d'une ordonnance
  Future<bool> updatePrescriptionStatus(String prescriptionId, String status) async {
    try {
      final repo = _ref.read(doctorPrescriptionRepositoryProvider);
      final success = await repo.updatePrescriptionStatus(prescriptionId, status);
      if (success) {
        // Mettre à jour la liste
        final prescriptions = state.prescriptions.map((p) {
          if (p.id == prescriptionId) {
            return p.copyWith(status: status);
          }
          return p;
        }).toList();
        state = state.copyWith(prescriptions: prescriptions);
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Erreur mise à jour statut prescription', error: e);
      return false;
    }
  }

  // Rafraîchir la liste
  Future<void> refresh() async {
    await loadPrescriptions();
  }
}
