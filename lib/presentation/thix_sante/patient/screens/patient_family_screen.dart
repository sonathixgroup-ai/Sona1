// 📁 lib/presentation/thix_sante/patient/screens/patient_family_screen.dart

import 'package:flutter/material.dart';
import '../../../common/screens/6_family_care_screen.dart';

class PatientFamilyScreen extends StatelessWidget {
  const PatientFamilyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Réutilise l'écran fusionné commun (famille + téléexpertise)
    return const FamilyCareScreen();
  }
}
