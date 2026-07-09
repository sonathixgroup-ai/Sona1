// lib/presentation/mon_pays/widgets/sections/exemplary_citizens_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/exemplary_citizen_model.dart';
import '../cards/citizen_card.dart';
import '../shared/section_title.dart';

class ExemplaryCitizensSection extends StatelessWidget {
  final List<ExemplaryCitizen> citizens;

  const ExemplaryCitizensSection({Key? key, required this.citizens})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (citizens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Citoyens Exemplaires',
          subtitle: 'Ils bâtissent la RDC chaque jour',
          seeAllText: 'Découvrir',
          onSeeAll: null,
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: citizens.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CitizenCard(citizen: citizens[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
