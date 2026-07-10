// lib/presentation/mon_pays/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'admin_provider.dart';
import 'admin_controller.dart'; // ✅ ajout
import 'admin_state.dart';
import '../widgets/app_bar.dart';
import '../utils/mon_pays_colors.dart';
import '../utils/mon_pays_text_styles.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminControllerProvider.notifier).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Administration - ${_getSectionLabel(state.activeSection)}',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshSection(state.activeSection),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, state.activeSection, controller),
      body: _buildSectionContent(state, controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, state.activeSection, controller),
        backgroundColor: MonPaysColors.primaryRed,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AdminSection activeSection, AdminController controller) {
    return Drawer(
      child: Container(
        color: MonPaysColors.primaryWhite,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: MonPaysColors.gradientBlueRed),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text('Mon Pays Admin', style: MonPaysTextStyles.heading5.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Gestion du contenu', style: MonPaysTextStyles.bodySmall.copyWith(color: Colors.white70)),
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
                    leading: Icon(_getIconForSection(section), color: activeSection == section ? MonPaysColors.primaryRed : MonPaysColors.textSecondary),
                    title: Text(_getSectionLabel(section), style: MonPaysTextStyles.bodyMedium.copyWith(color: activeSection == section ? MonPaysColors.primaryRed : MonPaysColors.textPrimary, fontWeight: activeSection == section ? FontWeight.bold : FontWeight.normal)),
                    onTap: () { controller.setActiveSection(section); Navigator.pop(context); },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Version 1.0.0', style: MonPaysTextStyles.caption.copyWith(color: MonPaysColors.textHint)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(AdminState state, AdminController controller) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: MonPaysColors.primaryRed),
            const SizedBox(height: 16),
            Text(state.error!, style: MonPaysTextStyles.bodyMedium.copyWith(color: MonPaysColors.primaryRed), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => controller.refreshSection(state.activeSection), child: const Text('Réessayer')),
          ],
        ),
      );
    }
    // Placeholder pour la liste des éléments
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gestion des ${_getSectionLabel(state.activeSection)}', style: MonPaysTextStyles.heading5.copyWith(color: MonPaysColors.primaryBlue)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _getListForSection(state, state.activeSection).length,
              itemBuilder: (context, index) {
                final item = _getListForSection(state, state.activeSection)[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.toString()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: MonPaysColors.primaryBlue), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete, color: MonPaysColors.primaryRed), onPressed: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, AdminSection section, AdminController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ajout d\'un nouvel élément à ${_getSectionLabel(section)}'), backgroundColor: MonPaysColors.primaryBlue),
    );
  }

  String _getSectionLabel(AdminSection section) {
    switch (section) {
      case AdminSection.authorities: return 'Autorités';
      case AdminSection.government: return 'Gouvernement';
      case AdminSection.ministries: return 'Ministères';
      case AdminSection.agencies: return 'Agences';
      case AdminSection.history: return 'Figures Historiques';
      case AdminSection.news: return 'Actualités';
      case AdminSection.laws: return 'Lois';
      case AdminSection.videos: return 'Vidéos';
      case AdminSection.documentaries: return 'Documentaires';
      case AdminSection.wanted: return 'Personnes Recherchées';
      case AdminSection.citizens: return 'Citoyens Exemplaires';
      case AdminSection.consultations: return 'Consultations';
    }
  }

  IconData _getIconForSection(AdminSection section) {
    switch (section) {
      case AdminSection.authorities: return Icons.person;
      case AdminSection.government: return Icons.account_balance;
      case AdminSection.ministries: return Icons.business_center;
      case AdminSection.agencies: return Icons.account_balance;
      case AdminSection.history: return Icons.history;
      case AdminSection.news: return Icons.newspaper;
      case AdminSection.laws: return Icons.gavel;
      case AdminSection.videos: return Icons.video_library;
      case AdminSection.documentaries: return Icons.movie;
      case AdminSection.wanted: return Icons.warning;
      case AdminSection.citizens: return Icons.people;
      case AdminSection.consultations: return Icons.poll;
    }
  }

  List<dynamic> _getListForSection(AdminState state, AdminSection section) {
    switch (section) {
      case AdminSection.authorities: return state.authorities;
      case AdminSection.government: return state.governments;
      case AdminSection.ministries: return state.ministries;
      case AdminSection.agencies: return state.agencies;
      case AdminSection.history: return state.historicalFigures;
      case AdminSection.news: return state.news;
      case AdminSection.laws: return state.laws;
      case AdminSection.videos: return state.videos;
      case AdminSection.documentaries: return state.documentaries;
      case AdminSection.wanted: return state.wantedPersons;
      case AdminSection.citizens: return state.exemplaryCitizens;
      case AdminSection.consultations: return state.consultations;
    }
  }
}
