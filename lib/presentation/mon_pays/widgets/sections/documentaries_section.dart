// lib/presentation/mon_pays/widgets/sections/documentaries_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/documentary_model.dart';
import '../cards/documentary_card.dart';
import '../shared/section_title.dart';

class DocumentariesSection extends StatelessWidget {
  final List<Documentary> documentaries;

  const DocumentariesSection({Key? key, required this.documentaries})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (documentaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Documentaires & Archives',
          subtitle: 'Plongez dans l\'histoire et la culture',
          seeAllText: 'Voir tout',
          onSeeAll: null,
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: documentaries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: DocumentaryCard(documentary: documentaries[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
