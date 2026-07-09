// lib/presentation/mon_pays/widgets/sections/values_laws_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/law_model.dart';
import '../shared/section_title.dart';

class ValuesLawsSection extends StatelessWidget {
  final List<Law> laws;

  const ValuesLawsSection({Key? key, required this.laws}) : super(key: key);

  // Icônes pour chaque catégorie (par défaut)
  static const Map<String, IconData> _icons = {
    'Constitution': Icons.gavel,
    'Institutions': Icons.account_balance,
    'Symboles Nationaux': Icons.flag,
    'Codes et Lois': Icons.book,
    'Droits du Citoyen': Icons.verified_user,
    'Devoirs du Citoyen': Icons.assignment,
    'Justice': Icons.scale,
    'Administration': Icons.business_center,
  };

  @override
  Widget build(BuildContext context) {
    // Si aucune loi fournie, on utilise une liste par défaut
    final List<Law> displayLaws = laws.isNotEmpty ? laws : _defaultLaws();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Valeurs & Lois',
          subtitle: 'Les fondements de la Nation',
          seeAllText: 'Voir tout',
          onSeeAll: null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: displayLaws.length,
            itemBuilder: (context, index) {
              final law = displayLaws[index];
              final icon = _icons[law.title] ?? Icons.library_books;
              return _buildLawButton(
                context,
                icon: icon,
                label: law.title,
                onTap: () {
                  // Navigation vers la page dédiée
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLawButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryRed.withOpacity(0.05),
                AppColors.primaryBlue.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Law> _defaultLaws() {
    return [
      Law(title: 'Constitution'),
      Law(title: 'Institutions'),
      Law(title: 'Symboles Nationaux'),
      Law(title: 'Codes et Lois'),
      Law(title: 'Droits du Citoyen'),
      Law(title: 'Devoirs du Citoyen'),
      Law(title: 'Justice'),
      Law(title: 'Administration'),
    ];
  }
}
