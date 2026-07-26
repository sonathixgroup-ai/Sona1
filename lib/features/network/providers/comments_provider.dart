import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/models/comment.dart';
import 'package:thix_id/features/network/data/network_service_provider.dart';

part 'comments_provider.g.dart';

@riverpod
class Comments extends _$Comments {
  static const int limit = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<Comment>> build(String postId) async {
    _offset = 0;
    _hasMore = true;
    final service = ref.read(networkServiceProvider);
    final all = await service.getCommentsWithReplies(postId);
    final page = all.take(limit).toList();
    _offset = page.length;
    _hasMore = all.length > limit;
    return page;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final service = ref.read(networkServiceProvider);
    final all = await service.getCommentsWithReplies(postId);
    if (_offset >= all.length) { _hasMore = false; return; }
    final end = (_offset + limit).clamp(0, all.length);
    final more = all.sublist(_offset, end);
    _offset = end;
    _hasMore = end < all.length;
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, ...more]);
  }

  Future<void> addComment(String content, {String? parentId}) async {
    final service = ref.read(networkServiceProvider);
    final newComment = await service.addComment(postId, content, parentId: parentId);
    final current = state.valueOrNull ?? [];
    if (parentId == null) {
      state = AsyncData([newComment, ...current]);
    } else {
      // insertion simple dans l'arbre
      for (var c in current) {
        if (c.id == parentId) { c.replies.insert(0, newComment); break; }
      }
      state = AsyncData([...current]);
    }
  }
}
