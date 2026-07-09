// lib/presentation/mon_pays/widgets/sections/wanted_persons_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/wanted_person_model.dart';
import '../cards/wanted_person_card.dart';
import '../shared/section_title.dart';

class WantedPersonsSection extends StatefulWidget {
  final List<WantedPerson> wantedPersons;

  const WantedPersonsSection({Key? key, required this.wantedPersons})
      : super(key: key);

  @override
  _WantedPersonsSectionState createState() => _WantedPersonsSectionState();
}

class _WantedPersonsSectionState extends State<WantedPersonsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dangerous = widget.wantedPersons
        .where((p) => p.type == WantedType.dangerous)
        .toList();
    final missing = widget.wantedPersons
        .where((p) => p.type == WantedType.missing)
        .toList();

    if (dangerous.isEmpty && missing.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
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
          // TabBar pour les onglets
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primaryRed,
              unselectedLabelColor: Colors.white,
              tabs: const [
                Tab(text: '🚨 Dangereuses'),
                Tab(text: '🔍 Disparues'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Contenu des onglets
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWantedList(dangerous),
                _buildWantedList(missing),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildWantedList(List<WantedPerson> persons) {
    if (persons.isEmpty) {
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
      itemCount: persons.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WantedPersonCard(person: persons[index]),
        );
      },
    );
  }
}
