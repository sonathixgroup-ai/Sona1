import 'package:flutter/material.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/profile_service.dart';
import '../../theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_shared_widgets.dart'; // Pour StatusChip
import '../editors/experience_editor_sheet.dart';
import '../editors/skills_editor_sheet.dart';

class ExperienceSkillsTab extends StatelessWidget {
  final String uid;
  final ThixProfile profile;
  final ProfileService profileService;

  const ExperienceSkillsTab({
    super.key,
    required this.uid,
    required this.profile,
    required this.profileService,
  });

  String _truncate(String v, int max) {
    final s = v.trim();
    if (s.length <= max) return s;
    return '${s.substring(0, max).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    // Colle ici TOUT le contenu de l'ancien build() de _ExperienceSkillsTab
    // Assure-toi de remplacer "user" par "profile" si nécessaire selon ton ancien code.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        children: [
          // Le DashboardCard des expériences...
          // Le DashboardCard des compétences...
        ],
      ),
    );
  }
}
