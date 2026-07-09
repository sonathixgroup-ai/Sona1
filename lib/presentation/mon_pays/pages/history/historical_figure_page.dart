// lib/presentation/mon_pays/pages/history/historical_figure_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/history_provider.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

class HistoricalFigurePage extends ConsumerWidget {
  final String id;

  const HistoricalFigurePage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figureAsync = ref.watch(historicalFigureProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail de la figure',
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
      body: figureAsync.when(
        data: (figure) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec image
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: MonPaysColors.gradientRedBlue,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      figure.imageUrl ?? 'https://via.placeholder.com/400',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom et période
                Text(
                  figure.name,
                  style: MonPaysTextStyles.heading4.copyWith(
                    color: MonPaysColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  figure.period,
                  style: MonPaysTextStyles.bodyLarge.copyWith(
                    color: MonPaysColors.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 32),

                // Biographie ou description
                if (figure.biography != null || figure.description != null) ...[
                  Text(
                    'Biographie',
                    style: MonPaysTextStyles.heading6.copyWith(
                      color: MonPaysColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    figure.biography ?? figure.description ?? '',
                    style: MonPaysTextStyles.bodyMedium.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action : retour
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
          child: ErrorWidget(
            message: 'Erreur de chargement : $error',
            onRetry: () => ref.refresh(historicalFigureProvider(id)),
          ),
        ),
      ),
    );
  }
}
