import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/news_article.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _newsService;
  List<NewsArticle> _articles=[]; List<NewsArticle> _videos=[]; List<NewsArticle> _saved=[]; bool _isLoading=false; String? _error; String _currentCategory='featured';
  NewsProvider(this._newsService);
  List<NewsArticle> get articles=>_articles; List<NewsArticle> get videos=>_videos; List<NewsArticle> get savedArticles=>_saved; bool get isLoading=>_isLoading; String? get error=>_error;

  Future<void> fetchArticles({String? category}) async { _isLoading=true; notifyListeners(); try{ _currentCategory=category??_currentCategory; _articles=await _newsService.getArticles(category:_currentCategory); }catch(e){_error=e.toString();} finally{_isLoading=false; notifyListeners();}}
  Future<void> fetchVideos() async { _videos=await _newsService.getVideos(); notifyListeners(); }
  Future<NewsArticle?> fetchArticleById(String id) async => await _newsService.getArticleById(id);
  Future<void> incrementViews(String id) async => await _newsService.incrementViews(id);
  Future<void> toggleLike(String id) async { final i=_articles.indexWhere((a)=>a.id==id); if(i!=-1){ final a=_articles[i]; if(a.isLiked){await _newsService.unlikeArticle(id); _articles[i]=a.copyWith(isLiked:false);} else{await _newsService.likeArticle(id); _articles[i]=a.copyWith(isLiked:true);} notifyListeners();}}
  Future<void> saveArticle(String id) async { await _newsService.saveArticle(id); _saved=await _newsService.getSavedArticles(); notifyListeners();}
  Future<void> unsaveArticle(String id) async { await _newsService.unsaveArticle(id); _saved=await _newsService.getSavedArticles(); notifyListeners();}
  Future<void> loadSavedArticles() async { _saved=await _newsService.getSavedArticles(); notifyListeners();}
  Future<List<NewsArticle>> getSavedArticlesList() async => await _newsService.getSavedArticles();
  Future<bool> isArticleSaved(String id) async => (await getSavedArticlesList()).any((a)=>a.id==id);

  Future<NewsArticle?> createArticle({required String title,String? summary,required String content,required String category,String? imageUrl,String? videoUrl,bool isFeatured=false,bool isBreaking=false}) async {
    try{ final a=await _newsService.createArticle(title:title,summary:summary,content:content,category:category,imageUrl:imageUrl,videoUrl:videoUrl,isFeatured:isFeatured,isBreaking:isBreaking); await fetchArticles(); return a; }catch(e){debugPrint('create $e'); return null;}
  }
  Future<void> updateArticle(String id, Map<String,dynamic> d) async { await _newsService.updateArticle(id,d); await fetchArticles(); }
  Future<void> deleteArticle(String id) async { await _newsService.deleteArticle(id); await fetchArticles(); }

  // FIX WEB
  Future<String?> uploadImageBytes(Uint8List bytes, String name) async => await _newsService.uploadImageBytes(bytes,name);
  Future<String?> uploadVideoBytes(Uint8List bytes, String name) async => await _newsService.uploadVideoBytes(bytes,name);
  Future<String?> uploadImage(String p) async => null;
  Future<String?> uploadVideo(String p) async => null;

  void setCategory(String c){ if(_currentCategory==c) return; _currentCategory=c; fetchArticles(category:c); }
  void refresh(){ fetchArticles(); fetchVideos(); loadSavedArticles(); }
}
