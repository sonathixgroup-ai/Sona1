// lib/presentation/mon_pays/sections/history_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/history_card.dart';
import '../providers/history_provider.dart';
import '../widgets/section_title.dart';

class HistorySection extends ConsumerWidget {
  const HistorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (figures) {
        if (figures.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Figures Historiques',
              subtitle: 'Découvrez ceux qui ont marqué notre histoire',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysHistory);
              },
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: figures.length,
                itemBuilder: (context, index) {
                  final figure = figures[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: HistoryCard(
                      figure: figure,
                      onTap: () {
                        context.push(
                          '${AppRoutes.monPaysHistoryDetail}'.replaceFirst(':id', figure.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 220,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
