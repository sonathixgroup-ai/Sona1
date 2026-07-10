// lib/presentation/mon_pays/repositories/emergency_repository.dart

import '../models/emergency_contact_model.dart';

class EmergencyRepository {
  Future<List<EmergencyContact>> getAll() async {
    // Returns hardcoded emergency contacts until a backend endpoint is available.
    return const [
      EmergencyContact(id: '1', name: 'Police Nationale', phoneNumber: '112', category: 'Sécurité'),
      EmergencyContact(id: '2', name: 'Pompiers', phoneNumber: '118', category: 'Incendie'),
      EmergencyContact(id: '3', name: 'SAMU / Ambulance', phoneNumber: '15', category: 'Santé'),
      EmergencyContact(id: '4', name: 'Protection Civile', phoneNumber: '122', category: 'Catastrophe'),
    ];
  }
}
