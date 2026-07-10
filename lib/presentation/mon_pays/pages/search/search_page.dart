// lib/presentation/mon_pays/pages/search/search_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_widget.dart';
import '../../cards/action_button_card.dart';
import '../../utils/mon_pays_colors.dart';
import '../../utils/mon_pays_text_styles.dart';
import '../../widgets/error_widget.dart';
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider(searchQuery));

    return Scaffold(
      appBar: MonPaysAppBar(
        title: 'Rechercher',
        showSearch: false,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: MonPaysColors.primaryWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: MonPaysColors.primaryRed.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MonPaysColors.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search,
                    color: MonPaysColors.primaryRed,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Rechercher dans Mon Pays...',
                        hintStyle: TextStyle(
                          color: MonPaysColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: MonPaysColors.darkText,
                        fontSize: 14,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                      onSubmitted: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: MonPaysColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        setState(() {});
                      },
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Résultats
          Expanded(
            child: searchQuery.isEmpty
                ? const _SearchInitialPlaceholder()
                : searchResultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return const EmptyWidget(
                          title: 'Aucun résultat',
                          message: 'Aucun résultat ne correspond à votre recherche',
                          icon: Icons.search_off,
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: result.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        result.imageUrl!,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.article,
                                          color: MonPaysColors.primaryRed,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.article,
                                      color: MonPaysColors.primaryRed,
                                    ),
                              title: Text(
                                result.title,
                                style: MonPaysTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: MonPaysColors.primaryBlue,
                                ),
                              ),
                              subtitle: Text(
                                result.description,
                                style: MonPaysTextStyles.caption.copyWith(
                                  color: MonPaysColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
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
                              onTap: () {
                                if (result.route != null) {
                                  context.push(result.route!);
                                } else {
                                  // Fallback : afficher un snackbar
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
                    loading: () => const Center(
                      child: LoadingWidget(message: 'Recherche en cours...'),
                    ),
                    error: (error, stack) => Center(
                      child: Text(
                        'Erreur: $error',
                        style: MonPaysTextStyles.bodyMedium.copyWith(
                          color: MonPaysColors.dangerRed,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchInitialPlaceholder extends StatelessWidget {
  const _SearchInitialPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: MonPaysColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Saisissez un mot-clé pour rechercher',
            style: TextStyle(
              color: MonPaysColors.textSecondary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Autorités, actualités, agences, lois...',
            style: TextStyle(
              color: MonPaysColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
