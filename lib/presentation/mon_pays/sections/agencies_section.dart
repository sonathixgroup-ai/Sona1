// lib/presentation/mon_pays/sections/agencies_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/agency_card.dart';
import '../providers/agencies_provider.dart';
import '../widgets/section_title.dart';

class AgenciesSection extends ConsumerWidget {
  const AgenciesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(agenciesProvider);

    return agenciesAsync.when(
      data: (agencies) {
        if (agencies.isEmpty) return const SizedBox.shrink();
        final displayAgencies = agencies.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Agences & Institutions',
              subtitle: 'Les piliers de l\'État',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysAgencies);
              },
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
                  final agency = displayAgencies[index];
                  return AgencyCard(
                    agency: agency,
                    onTap: () {
                      context.push(
                        '${AppRoutes.monPaysAgencyDetail}'.replaceFirst(':id', agency.id),
                      );
                    },
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
}// lib/presentation/mon_pays/sections/agencies_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/agency_card.dart';
import '../providers/agencies_provider.dart';
import '../widgets/section_title.dart';

class AgenciesSection extends ConsumerWidget {
  const AgenciesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(agenciesProvider);

    return agenciesAsync.when(
      data: (agencies) {
        if (agencies.isEmpty) return const SizedBox.shrink();
        final displayAgencies = agencies.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Agences & Institutions',
              subtitle: 'Les piliers de l\'État',
              seeAllText: 'Voir tout',
              onSeeAll: () {
                context.push(AppRoutes.monPaysAgencies);
              },
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
                  final agency = displayAgencies[index];
                  return AgencyCard(
                    agency: agency,
                    onTap: () {
                      context.push(
                        '${AppRoutes.monPaysAgencyDetail}'.replaceFirst(':id', agency.id),
                      );
                    },
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
