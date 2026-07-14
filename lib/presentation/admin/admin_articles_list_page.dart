import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/news_provider.dart';

class AdminArticlesListPage extends StatefulWidget {
  const AdminArticlesListPage({super.key});
  @override State<AdminArticlesListPage> createState() => _AdminArticlesListPageState();
}

class _AdminArticlesListPageState extends State<AdminArticlesListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NewsProvider>().fetchArticles(category: 'all'));
  }

  @override
  Widget build(BuildContext context) {
    final articles = context.watch<NewsProvider>().articles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer Articles'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/admin/articles/new'))],
      ),
      body: articles.isEmpty
          ? const Center(child: Text('Aucun article - Clique + pour créer'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = articles[i];
                return Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF4))),
                  child: ListTile(
                    leading: a.imageUrl != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(a.imageUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)))
                        : Container(width: 56, height: 56, color: Colors.grey[200], child: const Icon(Icons.article)),
                    title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${a.category} ${a.isFeatured ? "• À la une" : ""} ${a.isBreaking ? "• Breaking" : ""}'),
                    trailing: PopupMenuButton(
                      onSelected: (v) async {
                        if (v == 'edit') context.push('/admin/articles/${a.id}/edit');
                        if (v == 'delete') {
                          await context.read<NewsProvider>().deleteArticle(a.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supprimé')));
                        }
                      },
                      itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Éditer')), const PopupMenuItem(value: 'delete', child: Text('Supprimer'))],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
