import 'package:thix_id/features/thix_sante/core/thix_sante_exceptions.dart';
import 'package:thix_id/features/thix_sante/core/thix_sante_tables.dart';
import 'package:thix_id/features/thix_sante/domain/models/article_model.dart';
import 'package:thix_id/features/thix_sante/domain/repositories/article_repository.dart';
import 'package:thix_id/supabase/supabase_client.dart';

class SupabaseArticleRepository implements ArticleRepository {
  @override
  Stream<List<ArticleModel>> watchArticles({String? category}) {
    try {
      final cat = category?.trim();
      return supabase
          .from(ThixSanteTables.articles)
          .stream(primaryKey: const ['id'])
          .order('published_at', ascending: false)
          .map((rows) => rows
              .where((e) => cat == null || cat.isEmpty ? true : e['category'] == cat)
              .map((e) => ArticleModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false));
    } catch (e) {
      throw mapSupabaseError(e, context: 'watchArticles');
    }
  }

  @override
  Future<List<ArticleModel>> fetchArticles({String? category, int limit = 50, int offset = 0}) async {
    try {
      dynamic q = supabase.from(ThixSanteTables.articles).select('*');
      if (category != null && category.trim().isNotEmpty) {
        q = q.eq('category', category.trim());
      }

      final res = await q
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (res as List)
          .map((e) => ArticleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      throw mapSupabaseError(e, context: 'fetchArticles');
    }
  }
}
