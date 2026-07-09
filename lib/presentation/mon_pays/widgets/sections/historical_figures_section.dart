// lib/presentation/mon_pays/widgets/sections/historical_figures_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/historical_figure_model.dart';
import '../cards/history_card.dart';
import '../shared/section_title.dart';

class HistoricalFiguresSection extends StatelessWidget {
  final List<HistoricalFigure> figures;

  const HistoricalFiguresSection({Key? key, required this.figures})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (figures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Figures Historiques',
          subtitle: 'Découvrez ceux qui ont marqué notre histoire',
          seeAllText: 'Voir tout',
          onSeeAll: null,
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: figures.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: HistoryCard(figure: figures[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
