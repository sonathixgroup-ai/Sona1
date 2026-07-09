// lib/presentation/mon_pays/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admin_controller.dart';
import 'admin_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';

// Import des widgets de gestion pour chaque section (à créer)
import 'sections/manage_authorities.dart';
import 'sections/manage_historical.dart';
import 'sections/manage_news.dart';
import 'sections/manage_agencies.dart';
import 'sections/manage_videos.dart';
import 'sections/manage_documentaries.dart';
import 'sections/manage_wanted.dart';
import 'sections/manage_citizens.dart';
import 'sections/manage_laws.dart';
import 'sections/manage_consultations.dart';

class AdminDashboardPage extends StatelessWidget {
  AdminDashboardPage({super.key});

  final AdminController controller = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: Obx(() {
        // Gestion des états de chargement et d'erreur globaux
        if (controller.isLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.primaryRed),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: controller.loadAllData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        // Affichage du contenu selon la section active
        return _buildSectionContent(controller.activeSection);
      }),
      // Bouton flottant pour ajouter un élément (selon la section)
      floatingActionButton: Obx(() {
        if (controller.isLoading) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () => _showAddDialog(context, controller.activeSection),
          backgroundColor: AppColors.primaryRed,
          child: const Icon(Icons.add),
        );
      }),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Administration - ${controller.activeSection.label}',
        style: AppTextStyles.heading6.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.primaryBlue,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadAllData,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            // Déconnexion (à gérer avec AuthService)
            Get.back();
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.primaryWhite,
        child: Column(
          children: [
            // En-tête du drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryRed],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mon Pays Admin',
                    style: AppTextStyles.heading5.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestion du contenu',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: AdminSection.values.length,
                itemBuilder: (context, index) {
                  final section = AdminSection.values[index];
                  return ListTile(
                    leading: Icon(
                      _getIconForSection(section),
                      color: controller.activeSection == section
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      section.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: controller.activeSection == section
                            ? AppColors.primaryRed
                            : AppColors.textPrimary,
                        fontWeight: controller.activeSection == section
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      controller.setActiveSection(section);
                      Navigator.pop(context); // Ferme le drawer
                    },
                  );
                },
              ),
            ),
            // Footer du drawer
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(AdminSection section) {
    switch (section) {
      case AdminSection.authorities:
        return ManageAuthorities(controller: controller);
      case AdminSection.historical:
        return ManageHistorical(controller: controller);
      case AdminSection.news:
        return ManageNews(controller: controller);
      case AdminSection.agencies:
        return ManageAgencies(controller: controller);
      case AdminSection.videos:
        return ManageVideos(controller: controller);
      case AdminSection.documentaries:
        return ManageDocumentaries(controller: controller);
      case AdminSection.wanted:
        return ManageWanted(controller: controller);
      case AdminSection.citizens:
        return ManageCitizens(controller: controller);
      case AdminSection.laws:
        return ManageLaws(controller: controller);
      case AdminSection.consultations:
        return ManageConsultations(controller: controller);
    }
  }

  void _showAddDialog(BuildContext context, AdminSection section) {
    // Chaque section aura son propre dialogue d'ajout
    // Pour l'exemple, on affiche un SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajout d\'un nouvel élément à ${section.label}'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  IconData _getIconForSection(AdminSection section) {
    switch (section) {
      case AdminSection.authorities:
        return Icons.person;
      case AdminSection.historical:
        return Icons.history;
      case AdminSection.news:
        return Icons.newspaper;
      case AdminSection.agencies:
        return Icons.account_balance;
      case AdminSection.videos:
        return Icons.video_library;
      case AdminSection.documentaries:
        return Icons.movie;
      case AdminSection.wanted:
        return Icons.warning;
      case AdminSection.citizens:
        return Icons.people;
      case AdminSection.laws:
        return Icons.gavel;
      case AdminSection.consultations:
        return Icons.poll;
    }
  }
}
