// lib/presentation/mon_pays/pages/search/search_result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';

/// Page affichant les résultats de recherche en grand format.
/// Utile pour une vue détaillée des résultats.
class SearchResultPage extends ConsumerWidget {
  final String query;

  const SearchResultPage({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Résultats pour "$query"',
          style: MonPaysTextStyles.heading6.copyWith(color: Colors.white),
        ),
        backgroundColor: MonPaysColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return const EmptyWidget(
              title: 'Aucun résultat',
              message: 'Aucun résultat ne correspond à votre recherche',
              icon: Icons.search_off,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: result.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            result.imageUrl!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.article,
                              color: MonPaysColors.primaryRed,
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.article,
                          color: MonPaysColors.primaryRed,
                          size: 40,
                        ),
                  title: Text(
                    result.title,
                    style: MonPaysTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MonPaysColors.primaryBlue,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        result.description,
                        style: MonPaysTextStyles.bodySmall.copyWith(
                          color: MonPaysColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MonPaysColors.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.type,
                          style: MonPaysTextStyles.caption.copyWith(
                            color: MonPaysColors.primaryRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: MonPaysColors.primaryRed,
                  ),
                  onTap: () {
                    if (result.route != null) {
                      context.push(result.route!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Page en cours de développement'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: LoadingWidget()),
        error: (error, stack) => Center(
          child: Text(
            'Erreur: $error',
            style: MonPaysTextStyles.bodyMedium.copyWith(
              color: MonPaysColors.dangerRed,
            ),
          ),
        ),
      ),
    );
  }
}
