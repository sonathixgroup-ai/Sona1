// lib/services/news_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/news_article.dart';

class NewsService {
  final SupabaseClient _supabase;

  NewsService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ============================================================
  // LECTURE DES ARTICLES - VERSION CORRIGÉE
  // ============================================================

  Future<List<NewsArticle>> getArticles({
    String? category,
    int limit = 50,
    bool onlyPublished = true,
  }) async {
    try {
      debugPrint('📰 getArticles: chargement des articles...');
      
      // Récupérer tous les articles
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .order('published_at', ascending: false);
      
      debugPrint('📰 getArticles: ${(response as List).length} articles bruts');
      
      // Filtrer en Dart
      List<dynamic> results = response;
      
      // ✅ CORRIGÉ: Filtrer sur 'is_published' (boolean) au lieu de 'status'
      if (onlyPublished) {
        results = results.where((e) => e['is_published'] == true).toList();
        debugPrint('📰 getArticles: ${results.length} articles publiés');
      }
      
      // Filtrer par catégorie
      if (category != null && category.isNotEmpty && category != 'all' && category != 'featured') {
        results = results.where((e) => e['category'] == category).toList();
        debugPrint('📰 getArticles: ${results.length} articles dans catégorie $category');
      }
      
      // Articles à la une
      if (category == 'featured') {
        results = results.where((e) => e['is_featured'] == true).toList();
        debugPrint('📰 getArticles: ${results.length} articles à la une');
      }
      
      // Limiter
      results = results.take(limit).toList();
      
      // Convertir en objets
      final articles = <NewsArticle>[];
      for (var e in results) {
        final isLiked = await _isArticleLiked(e['id']);
        final isSaved = await _isArticleSaved(e['id']);
        
        articles.add(NewsArticle.fromJson({
          ...e,
          'is_liked': isLiked,
          'is_saved': isSaved,
        }));
      }
      
      debugPrint('✅ getArticles: ${articles.length} articles retournés');
      return articles;
    } catch (e) {
      debugPrint('❌ Error getArticles: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Récupérer l'article à la une
  Future<NewsArticle?> getFeaturedArticle() async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('is_featured', true)
          .eq('is_published', true)  // ← CORRIGÉ
          .order('published_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      
      final isLiked = await _isArticleLiked(response['id']);
      final isSaved = await _isArticleSaved(response['id']);
      
      return NewsArticle.fromJson({
        ...response,
        'is_liked': isLiked,
        'is_saved': isSaved,
      });
    } catch (e) {
      debugPrint('❌ Error getFeaturedArticle: $e');
      return null;
    }
  }

  // ✅ CORRIGÉ: Récupérer les articles récents
  Future<List<NewsArticle>> getRecentArticles({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('is_published', true)  // ← CORRIGÉ
          .order('published_at', ascending: false)
          .limit(limit);
      
      final articles = <NewsArticle>[];
      for (var e in response as List) {
        final isLiked = await _isArticleLiked(e['id']);
        final isSaved = await _isArticleSaved(e['id']);
        
        articles.add(NewsArticle.fromJson({
          ...e,
          'is_liked': isLiked,
          'is_saved': isSaved,
        }));
      }
      
      return articles;
    } catch (e) {
      debugPrint('❌ Error getRecentArticles: $e');
      return [];
    }
  }

  // ============================================================
  // AUTRES MÉTHODES
  // ============================================================

  Future<NewsArticle?> getArticleById(String articleId) async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('id', articleId)
          .maybeSingle();

      if (response == null) return null;

      final isLiked = await _isArticleLiked(articleId);
      final isSaved = await _isArticleSaved(articleId);

      return NewsArticle.fromJson({
        ...response,
        'is_liked': isLiked,
        'is_saved': isSaved,
      });
    } catch (e) {
      debugPrint('❌ Error getArticleById: $e');
      return null;
    }
  }

  // ✅ CORRIGÉ: Breaking news
  Future<List<NewsArticle>> getBreakingNews() async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('is_breaking', true)
          .eq('is_published', true)  // ← CORRIGÉ
          .order('published_at', ascending: false)
          .limit(20);
      
      final articles = <NewsArticle>[];
      for (var e in response as List) {
        articles.add(NewsArticle.fromJson(e));
      }
      return articles;
    } catch (e) {
      debugPrint('❌ Error getBreakingNews: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Vidéos
  Future<List<NewsArticle>> getVideos() async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('is_published', true)  // ← CORRIGÉ
          .not('video_url', 'is', null)
          .order('published_at', ascending: false)
          .limit(20);
      
      final articles = <NewsArticle>[];
      for (var e in response as List) {
        articles.add(NewsArticle.fromJson(e));
      }
      return articles;
    } catch (e) {
      debugPrint('❌ Error getVideos: $e');
      return [];
    }
  }

  // ✅ CORRIGÉ: Recherche
  Future<List<NewsArticle>> searchArticles(String query) async {
    try {
      final response = await _supabase
          .from('news_articles')
          .select('*')
          .eq('is_published', true)  // ← CORRIGÉ
          .or('title.ilike.%$query%,content.ilike.%$query%,summary.ilike.%$query%')
          .order('published_at', ascending: false)
          .limit(50);
      
      return (response as List).map((e) => NewsArticle.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Error searchArticles: $e');
      return [];
    }
  }

  // ============================================================
  // INTERACTIONS
  // ============================================================

  Future<void> incrementViews(String articleId) async {
    try {
      final article = await _supabase
          .from('news_articles')
          .select('views_count')
          .eq('id', articleId)
          .maybeSingle();
      
      if (article == null) return;
      
      final currentViews = article['views_count'] ?? 0;
      await _supabase
          .from('news_articles')
          .update({'views_count': currentViews + 1})
          .eq('id', articleId);
    } catch (e) {
      debugPrint('❌ Error incrementViews: $e');
    }
  }

  Future<bool> _isArticleLiked(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return false;

    try {
      final response = await _supabase
          .from('news_likes')
          .select('id')
          .eq('article_id', articleId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> likeArticle(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    final exists = await _isArticleLiked(articleId);
    if (!exists) {
      await _supabase.from('news_likes').insert({
        'article_id': articleId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> unlikeArticle(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    await _supabase
        .from('news_likes')
        .delete()
        .eq('article_id', articleId)
        .eq('user_id', currentUserId);
  }

  Future<bool> _isArticleSaved(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return false;

    try {
      final response = await _supabase
          .from('news_saved')
          .select('id')
          .eq('article_id', articleId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveArticle(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    final exists = await _isArticleSaved(articleId);
    if (!exists) {
      await _supabase.from('news_saved').insert({
        'article_id': articleId,
        'user_id': currentUserId,
        'saved_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> unsaveArticle(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    await _supabase
        .from('news_saved')
        .delete()
        .eq('article_id', articleId)
        .eq('user_id', currentUserId);
  }

  Future<List<NewsArticle>> getSavedArticles() async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return [];

    try {
      final response = await _supabase
          .from('news_saved')
          .select('article:article_id(*)')
          .eq('user_id', currentUserId)
          .order('saved_at', ascending: false);

      final articles = <NewsArticle>[];
      for (var e in response as List) {
        articles.add(NewsArticle.fromJson({
          ...e['article'],
          'is_saved': true,
        }));
      }
      return articles;
    } catch (e) {
      debugPrint('❌ Error getSavedArticles: $e');
      return [];
    }
  }

  // ============================================================
  // ADMIN - CRUD
  // ============================================================

  // ✅ CORRIGÉ: createArticle avec is_published
  Future<NewsArticle> createArticle({
    required String title,
    String? summary,
    required String content,
    required String category,
    String? imageUrl,
    String? videoUrl,
    bool isFeatured = false,
    bool isBreaking = false,
    DateTime? publishedAt,
  }) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    final now = DateTime.now().toIso8601String();
    final publishDate = (publishedAt ?? DateTime.now()).toIso8601String();

    debugPrint('📝 createArticle: Création de l\'article "$title"');
    debugPrint('   - catégorie: $category');
    debugPrint('   - isFeatured: $isFeatured');
    debugPrint('   - isBreaking: $isBreaking');

    final response = await _supabase.from('news_articles').insert({
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'is_featured': isFeatured,
      'is_breaking': isBreaking,
      'is_published': true,  // ← CORRIGÉ: is_published au lieu de status
      'published_at': publishDate,
      'created_at': now,
      'updated_at': now,
      'created_by': currentUserId,
      'views_count': 0,
    }).select().single();

    debugPrint('✅ createArticle: Article créé avec ID ${response['id']}');
    return NewsArticle.fromJson(response);
  }

  Future<void> updateArticle(String articleId, Map<String, dynamic> data) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    await _supabase
        .from('news_articles')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', articleId);
  }

  Future<void> deleteArticle(String articleId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    await _supabase.from('news_articles').delete().eq('id', articleId);
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<String?> uploadImage(String filePath) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return null;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final extension = filePath.split('.').last;
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = 'news_images/$fileName';
      
      await _supabase.storage
          .from('news_images')
          .uploadBinary(storagePath, bytes);
      
      return _supabase.storage.from('news_images').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadVideo(String filePath) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return null;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final extension = filePath.split('.').last;
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = 'news_videos/$fileName';
      
      await _supabase.storage
          .from('news_videos')
          .uploadBinary(storagePath, bytes);
      
      return _supabase.storage.from('news_videos').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return null;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Vérifier la connexion
  Future<bool> checkConnection() async {
    try {
      await _supabase.from('news_articles').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ Connection check failed: $e');
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Mettre à jour le statut de publication
  Future<void> setPublishStatus(String articleId, bool isPublished) async {
    try {
      await _supabase
          .from('news_articles')
          .update({'is_published': isPublished})
          .eq('id', articleId);
      debugPrint('📢 Article $articleId publié: $isPublished');
    } catch (e) {
      debugPrint('❌ Error setPublishStatus: $e');
    }
  }
}
