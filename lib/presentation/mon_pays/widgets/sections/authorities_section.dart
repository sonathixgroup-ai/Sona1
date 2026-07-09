// lib/presentation/mon_pays/widgets/sections/authorities_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/authority_model.dart';
import '../cards/authority_card.dart';
import '../shared/section_title.dart';

class AuthoritiesSection extends StatelessWidget {
  final List<Authority> authorities;

  const AuthoritiesSection({Key? key, required this.authorities})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (authorities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Autorités',
          subtitle: 'Les dirigeants de la Nation',
          seeAllText: 'Voir tout',
          onSeeAll: null, // Navigation vers la page complète
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: authorities.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AuthorityCard(authority: authorities[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
