import 'package:thix_id/features/thix_sante/domain/models/article_model.dart';

abstract class ArticleRepository {
  Stream<List<ArticleModel>> watchArticles({String? category});
  Future<List<ArticleModel>> fetchArticles({String? category, int limit = 50, int offset = 0});
}
