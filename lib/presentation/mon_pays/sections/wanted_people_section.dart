// lib/presentation/mon_pays/sections/wanted_people_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../cards/wanted_person_card.dart';
import '../providers/wanted_people_provider.dart';
import '../widgets/section_title.dart';
import '../utils/mon_pays_colors.dart';

class WantedPeopleSection extends ConsumerWidget {
  const WantedPeopleSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wantedAsync = ref.watch(wantedPeopleProvider);

    return wantedAsync.when(
      data: (people) {
        if (people.isEmpty) return const SizedBox.shrink();
        final dangerous = people.where((p) => p.status == WantedStatus.dangerous).toList();
        final missing = people.where((p) => p.status == WantedStatus.missing).toList();
        if (dangerous.isEmpty && missing.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: MonPaysColors.primaryRed,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: MonPaysColors.primaryRed.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Personnes Recherchées',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: MonPaysColors.primaryRed,
                          unselectedLabelColor: Colors.white,
                          tabs: const [
                            Tab(text: '🚨 Dangereuses'),
                            Tab(text: '🔍 Disparues'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          children: [
                            _buildWantedList(dangerous, context),
                            _buildWantedList(missing, context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox(
        height: 320,
        child: Center(child: Text('Erreur de chargement')),
      ),
    );
  }

  Widget _buildWantedList(List<WantedPerson> people, BuildContext context) {
    if (people.isEmpty) {
      return const Center(
        child: Text(
          'Aucune personne dans cette catégorie',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WantedPersonCard(
            person: person,
            onReport: () {
              // Ouvrir le dialogue de signalement
            },
            onTap: () {
              context.push(
                '${AppRoutes.monPaysWantedDetail}'.replaceFirst(':id', person.id),
              );
            },
          ),
        );
      },
    );
  }
}
