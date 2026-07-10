// lib/presentation/mon_pays/pages/agencies/agency_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/agencies_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class AgencyDetailPage extends ConsumerWidget {
  final String id;

  const AgencyDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyAsync = ref.watch(agencyProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail de l\'agence',
          style: MonPaysTextStyles.heading6.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: agencyAsync.when(
        data: (agency) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: MonPaysColors.gradientRedBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          agency.logoUrl ?? 'https://via.placeholder.com/80',
                          height: 60,
                          width: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          agency.name,
                          style: MonPaysTextStyles.heading5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations générales
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations générales',
                          style: MonPaysTextStyles.heading6.copyWith(
                            color: MonPaysColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (agency.description != null) ...[
                          Text(
                            agency.description!,
                            style: MonPaysTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (agency.type != null)
                          _infoRow('Type', agency.type.toString().split('.').last),
                        if (agency.website != null)
                          _infoRow('Site web', agency.website!),
                        if (agency.email != null)
                          _infoRow('Email', agency.email!),
                        if (agency.phone != null)
                          _infoRow('Téléphone', agency.phone!),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton vers les services (si applicable)
                if (agency.id.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '${AppRoutes.monPaysAgencyServices}'.replaceFirst(':id', agency.id),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Voir les services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MonPaysColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Retour
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: MonPaysColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(agencyProvider(id)),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: MonPaysTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: MonPaysColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MonPaysTextStyles.bodySmall.copyWith(
                color: MonPaysColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
