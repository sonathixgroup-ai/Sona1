// lib/presentation/mon_pays/pages/laws/article_type_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/article.dart';
import '../../providers/articles_provider.dart';
import 'article_detail_page.dart';

class ArticleTypePage extends ConsumerStatefulWidget {
  final ArticleType type;
  final String title;

  const ArticleTypePage({required this.type, required this.title, super.key});

  @override
  ConsumerState<ArticleTypePage> createState() => _ArticleTypePageState();
}

class _ArticleTypePageState extends ConsumerState<ArticleTypePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider(widget.type));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un article...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
      ),
      body: articlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (articles) {
          List<Article> filtered = articles;
          if (_searchQuery.isNotEmpty) {
            filtered = articles.where((a) =>
              a.title.toLowerCase().contains(_searchQuery) ||
              a.content.toLowerCase().contains(_searchQuery) ||
              (a.articleNumber?.toLowerCase().contains(_searchQuery) ?? false) ||
              (a.explanation?.toLowerCase().contains(_searchQuery) ?? false)
            ).toList();
          }
          if (filtered.isEmpty) {
            return const Center(child: Text('Aucun article trouvé.'));
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final article = filtered[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.article, color: Color(0xFF1A5276)),
                  title: Text(
                    article.articleNumber != null
                        ? 'Article ${article.articleNumber} - ${article.title}'
                        : article.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: article.chapter != null
                      ? Text('Chapitre ${article.chapter}')
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // ✅ CORRECTION : passer articleId au lieu de article
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailPage(articleId: article.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
