// lib/presentation/mon_pays/mon_pays_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import 'utils/mon_pays_colors.dart';
import 'utils/mon_pays_routes.dart';
import 'providers/mon_pays_provider.dart';
import 'widgets/app_bar.dart';
import 'widgets/loading_widget.dart';
import 'widgets/error_widget.dart';
import 'sections/authorities_section.dart';
import 'sections/history_section.dart';
import 'sections/news_section.dart';
import 'sections/values_section.dart';
import 'sections/agencies_section.dart';
import 'sections/videos_section.dart';
import 'sections/documentaries_section.dart';
import 'sections/wanted_people_section.dart';
import 'sections/citizens_section.dart';
import 'sections/consultations_section.dart';
import 'sections/emergency_section.dart';
import 'sections/banner_section.dart';

class MonPaysPage extends ConsumerStatefulWidget {
  const MonPaysPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MonPaysPage> createState() => _MonPaysPageState();
}

class _MonPaysPageState extends ConsumerState<MonPaysPage> {
  @override
  void initState() {
    super.initState();
    // Charger les données au premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monPaysControllerProvider.notifier).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monPaysControllerProvider);

    // Gestion des états de chargement et d'erreur
    if (state.isLoading) {
      return Scaffold(
        appBar: const MonPaysAppBar(),
        body: const Center(
          child: LoadingWidget(
            message: 'Chargement des données...',
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: const MonPaysAppBar(),
        body: Center(
          child: ErrorWidget(
            message: state.error!,
            onRetry: () {
              ref.read(monPaysControllerProvider.notifier).refreshData();
            },
          ),
        ),
      );
    }

    // Page principale avec toutes les sections
    return Scaffold(
      appBar: const MonPaysAppBar(),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Bannière (carrousel des actualités)
          const SliverToBoxAdapter(
            child: BannerSection(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Autorités
          const SliverToBoxAdapter(
            child: AuthoritiesSection(),
          ),

          // Figures Historiques
          const SliverToBoxAdapter(
            child: HistorySection(),
          ),

          // Actualités
          const SliverToBoxAdapter(
            child: NewsSection(),
          ),

          // Valeurs & Lois
          const SliverToBoxAdapter(
            child: ValuesSection(),
          ),

          // Agences & Institutions
          const SliverToBoxAdapter(
            child: AgenciesSection(),
          ),

          // Vidéos
          const SliverToBoxAdapter(
            child: VideosSection(),
          ),

          // Documentaires
          const SliverToBoxAdapter(
            child: DocumentariesSection(),
          ),

          // Personnes recherchées
          const SliverToBoxAdapter(
            child: WantedPeopleSection(),
          ),

          // Citoyens exemplaires
          const SliverToBoxAdapter(
            child: CitizensSection(),
          ),

          // Consultations publiques
          const SliverToBoxAdapter(
            child: ConsultationsSection(),
          ),

          // Urgence / Sécurité
          const SliverToBoxAdapter(
            child: EmergencySection(),
          ),

          // Espacement pour le bottom nav
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}
