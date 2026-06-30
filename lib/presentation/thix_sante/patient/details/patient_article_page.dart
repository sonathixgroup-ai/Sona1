// presentation/thix_sante/patient/details/patient_article_page.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientArticlePage extends StatefulWidget {
  final String articleId;
  const PatientArticlePage({super.key, required this.articleId});

  @override
  State<PatientArticlePage> createState() => _PatientArticlePageState();
}

class _PatientArticlePageState extends State<PatientArticlePage> {
  final HealthService _service = HealthService.instance;
  HealthArticle? _article;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      // Simuler un appel pour un article spécifique
      final all = await _service.fetchHealthArticles(limit: 10);
      final found = all.firstWhere((a) => a.id == widget.articleId);
      setState(() {
        _article = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_article!.imageUrl != null)
                      Image.network(_article!.imageUrl!,
                          height: 200, width: double.infinity, fit: BoxFit.cover),
                    const SizedBox(height: 12),
                    Text(
                      _article!.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_article!.author ?? 'Inconnu'} • ${_article!.publishDate.day}/${_article!.publishDate.month}/${_article!.publishDate.year} • ${_article!.readTime} min de lecture',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _article!.content,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: _article!.tags.map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
