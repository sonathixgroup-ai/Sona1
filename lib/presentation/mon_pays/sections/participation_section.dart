// lib/presentation/mon_pays/sections/participation_section.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/action_button_card.dart';
import '../utils/mon_pays_colors.dart';

class ParticipationSection extends StatelessWidget {
  const ParticipationSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ActionButtonCard(
        icon: Icons.mic,
        title: 'Participer & S\'exprimer',
        subtitle: 'Donnez votre avis, contribuez aux consultations',
        backgroundColor: MonPaysColors.primaryBlue.withOpacity(0.1),
        iconColor: MonPaysColors.primaryRed,
        onTap: () {
          context.push(AppRoutes.monPaysConsultations);
        },
      ),
    );
  }
}
