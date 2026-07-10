// lib/presentation/mon_pays/pages/wanted_people/wanted_people_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routes/app_routes.dart';
import '../../widgets/app_bar.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import 'dangerous_people_page.dart';
import 'missing_people_page.dart';

class WantedPeoplePage extends StatelessWidget {
  const WantedPeoplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Personnes Recherchées',
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MonPaysColors.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: MonPaysColors.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: MonPaysColors.primaryRed,
                tabs: const [
                  Tab(text: '🚨 Dangereuses'),
                  Tab(text: '🔍 Disparues'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: const [
                  DangerousPeoplePage(),
                  MissingPeoplePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
