// lib/presentation/mon_pays/widgets/sections/consultation_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/consultation_model.dart';
import '../shared/section_title.dart';

class ConsultationSection extends StatelessWidget {
  final List<Consultation> consultations;

  const ConsultationSection({Key? key, required this.consultations})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeConsultations = consultations
        .where((c) => c.isActive)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Consultations Publiques',
          subtitle: 'Participez à la construction du pays',
          seeAllText: 'Voir toutes',
          onSeeAll: null,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: activeConsultations.length,
          itemBuilder: (context, index) {
            final consultation = activeConsultations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.poll,
                    color: AppColors.primaryRed,
                  ),
                ),
                title: Text(
                  consultation.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Jusqu\'au ${consultation.endDate}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
                onTap: () {
                  // Navigation vers le détail de la consultation
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
