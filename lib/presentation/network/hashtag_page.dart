import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/services/network_service.dart';

class HashtagPage extends StatefulWidget {
  final String tag;
  const HashtagPage({super.key, required this.tag});

  @override
  State<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  late NetworkService _networkService;
  List<NetworkPost> _posts = [];
  bool _loading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  int _offset = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _networkService = Provider.of<NetworkService>(context, listen: false);
    _loadData();
    _scrollController.addListener(() {
      if(_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) _loadMore();
    });
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; _offset = 0; });
    try {
      final posts = await _networkService.getPostsByHashtag(widget.tag, limit: 30, offset: 0);
      if(!mounted) return;
      setState(() { _posts = posts; _offset = posts.length; _hasMore = posts.length == 30; _loading = false; });
    } catch(e) {
      if(mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if(!_hasMore) return;
    final more = await _networkService.getPostsByHashtag(widget.tag, limit: 30, offset: _offset);
    if(!mounted) return;
    setState(() { _posts.addAll(more); _offset += more.length; _hasMore = more.length == 30; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(children: [const Icon(Icons.tag, color: Color(0xFFD4AF37)), const SizedBox(width:8), Text('#${widget.tag}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)))]),
        actions: [Container(margin: const EdgeInsets.only(right:16), padding: const EdgeInsets.symmetric(horizontal:12, vertical:6), decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text('${_posts.length} posts', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600)))],
      ),
      body: _loading? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
        : _error!= null? Center(child: Text(_error!))
        : _posts.isEmpty? Center(child: Text('Aucun post pour #${widget.tag}'))
        : RefreshIndicator(onRefresh: _loadData, child: GridView.builder(controller: _scrollController, padding: const EdgeInsets.all(2), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2), itemCount: _posts.length, itemBuilder: (c,i) => _buildPostItem(_posts[i]))),
    );
  }

  Widget _buildPostItem(NetworkPost post) {
    final hasImage = post.mediaUrls.isNotEmpty;
    return GestureDetector(
      onTap: () => context.push('/network/post/${post.id}'),
      child: hasImage
        ? CachedNetworkImage(imageUrl: post.mediaUrls.first, fit: BoxFit.cover, memCacheWidth: 300, placeholder: (_,__) => Container(color: Colors.grey.shade200), errorWidget: (_,__,___) => const Icon(Icons.broken_image))
        : Container(color: Colors.grey.shade200, child: Center(child: Text(post.content.length>20? '${post.content.substring(0,20)}...' : post.content, maxLines: 2, style: const TextStyle(fontSize:10)))),
    );
  }
}
