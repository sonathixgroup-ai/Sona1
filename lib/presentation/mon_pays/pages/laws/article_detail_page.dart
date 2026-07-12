// lib/presentation/mon_pays/pages/laws/article_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/article.dart';
import '../../providers/articles_provider.dart';

class ArticleDetailPage extends ConsumerWidget {
  final String articleId;

  const ArticleDetailPage({required this.articleId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleDetailProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: articleAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'article...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(articleDetailProvider(articleId));
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (article) => _buildContent(context, article),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Article article) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            article.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (article.chapter != null) ...[
            const SizedBox(height: 8),
            Text('Chapitre : ${article.chapter}',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
          if (article.articleNumber != null) ...[
            const SizedBox(height: 4),
            Text('Article : ${article.articleNumber}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
          const Divider(height: 32),
          // Contenu
          const Text('Contenu', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            article.content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          // Explication (optionnelle)
          if (article.explanation != null && article.explanation!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1A5276)),
                      const SizedBox(width: 8),
                      const Text('Explication',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.explanation!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          // Status
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                article.isPublished ? Icons.check_circle : Icons.lock_outline,
                color: article.isPublished ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                article.isPublished ? 'Publié' : 'Brouillon',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (article.publishedAt != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Publié le ${_formatDate(article.publishedAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
