// lib/presentation/mon_pays/providers/emergency_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact_model.dart';
import '../repositories/emergency_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>(
  (_) => EmergencyRepository(),
);

final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final repo = ref.watch(emergencyRepositoryProvider);
  return repo.getAll();
});

final emergencyStateProvider = StateProvider<bool>((ref) => false);
