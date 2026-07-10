// lib/presentation/mon_pays/admin/widgets/admin_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_provider.dart';
import '../admin_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminMenu extends ConsumerWidget {
  final VoidCallback? onLogout;

  const AdminMenu({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
    final controller = ref.read(adminControllerProvider.notifier);

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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                  final isActive = state.activeSection == section;
                  return ListTile(
                    leading: Icon(
                      _getIconForSection(section),
                      color: isActive
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      _getSectionLabel(section),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isActive
                            ? AppColors.primaryRed
                            : AppColors.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? Container(
                            width: 4,
                            height: 24,
                            color: AppColors.primaryRed,
                          )
                        : null,
                    onTap: () {
                      controller.setActiveSection(section);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            // Footer du drawer
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    'Version 1.0.0',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                  const Spacer(),
                  if (onLogout != null)
                    TextButton(
                      onPressed: onLogout,
                      child: Text(
                        'Déconnexion',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionLabel(AdminSection section) {
    switch (section) {
      case AdminSection.authorities:
        return 'Autorités';
      case AdminSection.government:
        return 'Gouvernement';
      case AdminSection.ministries:
        return 'Ministères';
      case AdminSection.agencies:
        return 'Agences';
      case AdminSection.history:
        return 'Figures Historiques';
      case AdminSection.news:
        return 'Actualités';
      case AdminSection.laws:
        return 'Lois';
      case AdminSection.videos:
        return 'Vidéos';
      case AdminSection.documentaries:
        return 'Documentaires';
      case AdminSection.wanted:
        return 'Personnes Recherchées';
      case AdminSection.citizens:
        return 'Citoyens Exemplaires';
      case AdminSection.consultations:
        return 'Consultations';
    }
  }

  IconData _getIconForSection(AdminSection section) {
    switch (section) {
      case AdminSection.authorities:
        return Icons.person;
      case AdminSection.government:
        return Icons.account_balance;
      case AdminSection.ministries:
        return Icons.business_center;
      case AdminSection.agencies:
        return Icons.account_balance;
      case AdminSection.history:
        return Icons.history;
      case AdminSection.news:
        return Icons.newspaper;
      case AdminSection.laws:
        return Icons.gavel;
      case AdminSection.videos:
        return Icons.video_library;
      case AdminSection.documentaries:
        return Icons.movie;
      case AdminSection.wanted:
        return Icons.warning;
      case AdminSection.citizens:
        return Icons.people;
      case AdminSection.consultations:
        return Icons.poll;
    }
  }
}
