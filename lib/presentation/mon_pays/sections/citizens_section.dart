// lib/presentation/mon_pays/sections/citizens_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/citizen_card.dart';
import '../providers/citizens_provider.dart';
import '../widgets/section_title.dart';

class CitizensSection extends ConsumerWidget {
  const CitizensSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citizensAsync = ref.watch(citizensProvider);

    return citizensAsync.when(
      data: (citizens) {
        if (citizens.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Citoyens Exemplaires',
              subtitle: 'Ils bâtissent la RDC chaque jour',
              seeAllText: 'Découvrir',
              onSeeAll: () {
                context.push(AppRoutes.monPaysCitizens);
              },
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: citizens.length,
                itemBuilder: (context, index) {
                  final citizen = citizens[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CitizenCard(
                      citizen: citizen,
                      onTap: () {
                        context.push(
                          '${AppRoutes.monPaysCitizenDetail}'.replaceFirst(':id', citizen.id),
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
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 200,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }
}
