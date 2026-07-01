// presentation/thix_sante/patient/details/patient_article_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientArticlePage extends StatefulWidget {
  final String articleId;

  const PatientArticlePage({super.key, required this.articleId});

  @override
  State<PatientArticlePage> createState() => _PatientArticlePageState();
}

class _PatientArticlePageState extends State<PatientArticlePage> {
  final HealthService _healthService = HealthService.instance;
  HealthArticle? _article;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer tous les articles et filtrer par ID
      final articles = await _healthService.fetchHealthArticles(limit: 50);
      final found = articles.firstWhere(
        (a) => a.id == widget.articleId,
        orElse: () => throw Exception('Article introuvable'),
      );
      setState(() {
        _article = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'article depuis les paramètres de la route (extra)
    // Utiliser GoRouterState pour accéder à extra
    final extraArticle = GoRouterState.of(context).extra as HealthArticle?;
    if (extraArticle != null && _article == null && !_isLoading) {
      // Utiliser l'article passé en extra (si disponible)
      setState(() {
        _article = extraArticle;
        _isLoading = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article santé'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadArticle,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _article == null
                  ? const Center(child: Text('Article introuvable'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final article = _article!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (si disponible)
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                article.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          const SizedBox(height: 16),
          // Titre
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Métadonnées : auteur, date, temps de lecture
          Row(
            children: [
              if (article.author != null)
                Text(
                  article.author!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              if (article.author != null) const SizedBox(width: 8),
              Text(
                _formatDate(article.publishDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${article.readTime} min de lecture',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sous-titre
          Text(
            article.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Tags
          if (article.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              children: article.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF2563FF).withOpacity(0.1),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          // Contenu (formaté)
          Text(
            article.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Bouton de retour
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
