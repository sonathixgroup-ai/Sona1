// lib/presentation/mon_pays/pages/laws/article_detail_page.dart

import 'package:flutter/material.dart';
import '../../models/article.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({required this.article, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.articleNumber != null
            ? 'Article ${article.articleNumber}'
            : article.title),
      ),
      body: SingleChildScrollView(
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
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 16),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
