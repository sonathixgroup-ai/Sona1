// lib/presentation/mon_pays/providers/emergency_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact_model.dart'; // (à définir)
import '../repositories/emergency_repository.dart'; // (à définir)

// Exemple simple, peut être adapté selon vos besoins
final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  // Ajoutez votre logique
  return [];
});

// Ou bien un StateProvider pour gérer l'état d'urgence
final emergencyStateProvider = StateProvider<bool>((ref) => false);
