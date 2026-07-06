// lib/presentation/thix_info/article_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

class ArticleDetailPage extends StatefulWidget {
  final String articleId;
  const ArticleDetailPage({super.key, required this.articleId});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late NewsArticle _article;
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    final provider = context.read<NewsProvider>();
    final article = await provider.fetchArticleById(widget.articleId);
    if (article != null) {
      setState(() {
        _article = article;
        _isLoading = false;
      });
      await provider.incrementViews(widget.articleId);
      _checkIfSaved();
    }
  }

  Future<void> _checkIfSaved() async {
    final provider = context.read<NewsProvider>();
    final saved = await provider.isArticleSaved(widget.articleId);
    setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    final provider = context.read<NewsProvider>();
    if (_isSaved) {
      await provider.unsaveArticle(widget.articleId);
    } else {
      await provider.saveArticle(widget.articleId);
    }
    setState(() => _isSaved = !_isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isSaved ? 'Article sauvegardé' : 'Retiré des favoris'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _shareArticle() async {
    await Share.share('${_article.title}\n\n${_article.summary}\n\nLire plus sur THIX INFO');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFD4AF37)),
            onPressed: _toggleSave,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: _shareArticle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_article.imageUrl != null && _article.imageUrl!.isNotEmpty)
              Image.network(
                _article.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _article.category.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _article.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(_article.publishedAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${_article.viewsCount} vues',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _article.content,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
