// 📁 lib/presentation/thix_sante/patient/screens/patient_tracking_screen.dart

import 'package:flutter/material.dart';
import '../../../common/screens/1_health_tracking_screen.dart';

class PatientTrackingScreen extends StatelessWidget {
  const PatientTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Réutilise l'écran fusionné commun
    return const HealthTrackingScreen();
  }
}
