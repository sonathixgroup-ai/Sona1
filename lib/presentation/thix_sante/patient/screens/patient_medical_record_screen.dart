// 📁 lib/presentation/thix_sante/patient/screens/patient_medical_record_screen.dart

import 'package:flutter/material.dart';
import '../../../common/screens/4_medical_documents_screen.dart';

class PatientMedicalRecordScreen extends StatelessWidget {
  const PatientMedicalRecordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Réutilise l'écran fusionné commun (vaccins, documents, partage)
    return const MedicalDocumentsScreen();
  }
}
