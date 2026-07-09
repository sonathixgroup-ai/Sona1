// lib/presentation/mon_pays/sections/emergency_section.dart

import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/action_button_card.dart';
import '../utils/mon_pays_colors.dart';

class EmergencySection extends StatelessWidget {
  const EmergencySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ActionButtonCard(
        icon: Icons.emergency_rounded,
        title: 'Urgence & Sécurité',
        subtitle: 'Signaler une urgence ou une situation dangereuse',
        backgroundColor: MonPaysColors.dangerRed,
        iconColor: Colors.white,
        onTap: () {
          context.push(AppRoutes.monPaysEmergency);
        },
      ),
    );
  }
}
