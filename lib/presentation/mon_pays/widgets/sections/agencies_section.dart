// lib/presentation/mon_pays/widgets/sections/agencies_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/agency_model.dart';
import '../cards/agency_card.dart';
import '../shared/section_title.dart';

class AgenciesSection extends StatelessWidget {
  final List<Agency> agencies;

  const AgenciesSection({Key? key, required this.agencies}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (agencies.isEmpty) {
      return const SizedBox.shrink();
    }

    // Afficher les 6 premières en grille
    final displayAgencies = agencies.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Agences & Institutions',
          subtitle: 'Les piliers de l\'État',
          seeAllText: 'Voir tout',
          onSeeAll: null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: displayAgencies.length,
            itemBuilder: (context, index) {
              return AgencyCard(agency: displayAgencies[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
