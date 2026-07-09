// lib/presentation/mon_pays/mon_pays_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mon_pays_controller.dart';
import 'mon_pays_state.dart';
import '../../services/mon_pays_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/error_placeholder.dart';

// Import des sections
import 'widgets/header/app_bar_mon_pays.dart';
import 'widgets/sections/authorities_section.dart';
import 'widgets/sections/historical_figures_section.dart';
import 'widgets/sections/official_news_section.dart';
import 'widgets/sections/values_laws_section.dart';
import 'widgets/sections/agencies_section.dart';
import 'widgets/sections/videos_section.dart';
import 'widgets/sections/documentaries_section.dart';
import 'widgets/sections/wanted_persons_section.dart';
import 'widgets/sections/exemplary_citizens_section.dart';
import 'widgets/sections/participation_section.dart';
import 'widgets/sections/consultation_section.dart';

// Admin
import 'admin/admin_dashboard_page.dart';

class MonPaysPage extends StatelessWidget {
  MonPaysPage({super.key});

  // Injection des dépendances (GetX)
  final MonPaysController controller = Get.put(
    MonPaysController(
      Get.find<MonPaysService>(),
      Get.find<AuthService>(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MonPaysAppBar(),
      body: Obx(() {
        // Gestion des états de chargement et d'erreur
        if (controller.isLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (controller.errorMessage != null) {
          return ErrorPlaceholder(
            message: controller.errorMessage!,
            onRetry: controller.refreshData,
          );
        }

        return CustomScrollView(
          slivers: [
            // Hero Banner (carrousel des actualités)
            SliverToBoxAdapter(
              child: _buildHeroBanner(context),
            ),

            // Autorités
            SliverToBoxAdapter(
              child: AuthoritiesSection(authorities: controller.authorities),
            ),

            // Figures Historiques
            SliverToBoxAdapter(
              child: HistoricalFiguresSection(
                figures: controller.historicalFigures,
              ),
            ),

            // Actualités Officielles
            SliverToBoxAdapter(
              child: OfficialNewsSection(news: controller.news),
            ),

            // Valeurs & Lois (grille)
            SliverToBoxAdapter(
              child: ValuesLawsSection(laws: controller.laws),
            ),

            // Agences & Institutions
            SliverToBoxAdapter(
              child: AgenciesSection(agencies: controller.agencies),
            ),

            // Vidéos Officielles
            SliverToBoxAdapter(
              child: VideosSection(videos: controller.videos),
            ),

            // Documentaires
            SliverToBoxAdapter(
              child: DocumentariesSection(
                documentaries: controller.documentaries,
              ),
            ),

            // Personnes recherchées (carte rouge)
            SliverToBoxAdapter(
              child: WantedPersonsSection(
                wantedPersons: controller.wantedPersons,
              ),
            ),

            // Citoyens Exemplaires
            SliverToBoxAdapter(
              child: ExemplaryCitizensSection(
                citizens: controller.exemplaryCitizens,
              ),
            ),

            // Participer & S'exprimer
            SliverToBoxAdapter(
              child: ParticipationSection(),
            ),

            // Consultations Publiques
            SliverToBoxAdapter(
              child: ConsultationSection(
                consultations: controller.consultations,
              ),
            ),

            // Footer (espacement)
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      }),
      // Bouton flottant Admin (visible uniquement pour admin/moderateur)
      floatingActionButton: Obx(() {
        if (!controller.isAdminOrModerator) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const AdminDashboardPage());
          },
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Admin'),
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: 6,
        );
      }),
    );
  }

  // Widget Hero Banner (exemple avec un carrousel)
  Widget _buildHeroBanner(BuildContext context) {
    final news = controller.news.take(3).toList();
    if (news.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: PageView.builder(
        itemCount: news.length,
        itemBuilder: (context, index) {
          final item = news[index];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: AppTextStyles.heading4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  item.date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
