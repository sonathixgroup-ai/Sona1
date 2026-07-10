// lib/presentation/mon_pays/pages/agencies/agency_services_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/agencies_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

// Note : Ce fichier suppose que vous avez un modèle `Service` ou un service associé.
// Si ce n'est pas le cas, vous pouvez adapter pour afficher des informations
// supplémentaires ou un message indiquant que les services ne sont pas disponibles.

class AgencyServicesPage extends ConsumerWidget {
  final String agencyId;

  const AgencyServicesPage({Key? key, required this.agencyId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyAsync = ref.watch(agencyProvider(agencyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Services',
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
          // Exemple de liste de services fictifs
          // Dans un cas réel, vous pourriez avoir un provider `agencyServicesProvider(agencyId)`
          final services = [
            {'name': 'Service 1', 'description': 'Description du service 1'},
            {'name': 'Service 2', 'description': 'Description du service 2'},
            {'name': 'Service 3', 'description': 'Description du service 3'},
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Services proposés par ${agency.name}',
                  style: MonPaysTextStyles.heading5.copyWith(
                    color: MonPaysColors.primaryBlue,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MonPaysColors.primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.build,
                            color: MonPaysColors.primaryRed,
                          ),
                        ),
                        title: Text(
                          service['name']!,
                          style: MonPaysTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          service['description']!,
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.textSecondary,
                          ),
                        ),
                        onTap: () {
                          // Navigation vers le détail du service si nécessaire
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: MonPaysErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(agencyProvider(agencyId)),
          ),
        ),
      ),
    );
  }
}
