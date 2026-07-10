// lib/presentation/mon_pays/pages/values/values_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../widgets/app_bar.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../utils/mon_pays_icons.dart';

class ValuesPage extends StatelessWidget {
  const ValuesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'Constitution', 'icon': Icons.gavel, 'route': AppRoutes.monPaysConstitution},
      {'title': 'Lois', 'icon': Icons.book, 'route': AppRoutes.monPaysLaws},
      {'title': 'Institutions', 'icon': Icons.account_balance, 'route': AppRoutes.monPaysInstitutions},
      {'title': 'Droits du Citoyen', 'icon': Icons.verified_user, 'route': AppRoutes.monPaysRights},
      {'title': 'Devoirs du Citoyen', 'icon': Icons.assignment, 'route': AppRoutes.monPaysDuties},
      {'title': 'Justice', 'icon': Icons.scale, 'route': AppRoutes.monPaysJustice},
    ];

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Valeurs & Lois',
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.push(category['route'] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MonPaysColors.primaryRed.withOpacity(0.05),
                      MonPaysColors.primaryBlue.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: MonPaysColors.primaryRed,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category['title'] as String,
                      style: MonPaysTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MonPaysColors.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
