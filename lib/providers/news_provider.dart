// lib/providers/news_provider.dart
import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/news_article.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _newsService;

  List<NewsArticle> _articles = [];
  List<NewsArticle> _videos = [];
  List<NewsArticle> _savedArticles = [];
  bool _isLoading = false;
  String? _error;
  String _currentCategory = 'featured';

  NewsProvider(this._newsService);

  // Getters
  List<NewsArticle> get articles => _articles;
  List<NewsArticle> get videos => _videos;
  List<NewsArticle> get savedArticles => _savedArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;

  NewsArticle? get featuredArticle {
    final featured = _articles.where((a) => a.isFeatured).toList();
    if (featured.isNotEmpty) return featured.first;
    if (_articles.isNotEmpty) return _articles.first;
    return null;
  }

  List<NewsArticle> get recentArticles {
    return _articles.where((a) => !a.isFeatured).take(10).toList();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> fetchArticles({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCategory = category ?? _currentCategory;
      _currentCategory = newCategory;
      _articles = await _newsService.getArticles(category: newCategory);
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchArticles error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchVideos() async {
    try {
      _videos = await _newsService.getVideos();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchVideos error: $e');
    }
  }

  Future<NewsArticle?> fetchArticleById(String id) async {
    try {
      return await _newsService.getArticleById(id);
    } catch (e) {
      debugPrint('❌ fetchArticleById error: $e');
      return null;
    }
  }

  Future<List<NewsArticle>> fetchArticlesByCategory(String category) async {
    try {
      return await _newsService.getArticles(category: category);
    } catch (e) {
      debugPrint('❌ fetchArticlesByCategory error: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> fetchBreakingNews() async {
    try {
      return await _newsService.getBreakingNews();
    } catch (e) {
      debugPrint('❌ fetchBreakingNews error: $e');
      return [];
    }
  }

  Future<List<NewsArticle>> searchArticles(String query) async {
    try {
      return await _newsService.searchArticles(query);
    } catch (e) {
      debugPrint('❌ searchArticles error: $e');
      return [];
    }
  }

  // ============================================================
  // INTERACTIONS (Likes, Vues, Favoris)
  // ============================================================

  Future<void> incrementViews(String articleId) async {
    await _newsService.incrementViews(articleId);
  }

  Future<void> toggleLike(String articleId) async {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = _articles[index];
      if (article.isLiked) {
        await _newsService.unlikeArticle(articleId);
        _articles[index] = article.copyWith(isLiked: false);
      } else {
        await _newsService.likeArticle(articleId);
        _articles[index] = article.copyWith(isLiked: true);
      }
      notifyListeners();
    }
  }

  Future<bool> isArticleSaved(String articleId) async {
    final saved = await getSavedArticlesList();
    return saved.any((a) => a.id == articleId);
  }

  Future<void> saveArticle(String articleId) async {
    await _newsService.saveArticle(articleId);
    
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isSaved: true);
    }
    
    await loadSavedArticles();
    notifyListeners();
  }

  Future<void> unsaveArticle(String articleId) async {
    await _newsService.unsaveArticle(articleId);
    
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isSaved: false);
    }
    
    await loadSavedArticles();
    notifyListeners();
  }

  Future<void> loadSavedArticles() async {
    try {
      _savedArticles = await getSavedArticlesList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadSavedArticles error: $e');
    }
  }

  // ⭐ UNE SEULE FOIS - Méthode pour récupérer les articles sauvegardés
  Future<List<NewsArticle>> getSavedArticlesList() async {
    return await _newsService.getSavedArticles();
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<NewsArticle?> createArticle({
    required String title,
    String? summary,
    required String content,
    required String category,
    String? imageUrl,
    String? videoUrl,
    bool isFeatured = false,
    bool isBreaking = false,
  }) async {
    try {
      final article = await _newsService.createArticle(
        title: title,
        summary: summary,
        content: content,
        category: category,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        isFeatured: isFeatured,
        isBreaking: isBreaking,
      );
      await fetchArticles();
      return article;
    } catch (e) {
      debugPrint('❌ createArticle error: $e');
      return null;
    }
  }

  Future<void> updateArticle(String articleId, Map<String, dynamic> data) async {
    try {
      await _newsService.updateArticle(articleId, data);
      await fetchArticles();
    } catch (e) {
      debugPrint('❌ updateArticle error: $e');
    }
  }

  Future<void> deleteArticle(String articleId) async {
    try {
      await _newsService.deleteArticle(articleId);
      await fetchArticles();
    } catch (e) {
      debugPrint('❌ deleteArticle error: $e');
    }
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<String?> uploadImage(String filePath) async {
    return await _newsService.uploadImage(filePath);
  }

  Future<String?> uploadVideo(String filePath) async {
    return await _newsService.uploadVideo(filePath);
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void setCategory(String category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    fetchArticles(category: category);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    fetchArticles();
    fetchVideos();
    loadSavedArticles();
  }
}
