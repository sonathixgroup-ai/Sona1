import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';
import 'package:thix_id/presentation/network/widgets/post_card.dart';

class MyPostsPage extends ConsumerStatefulWidget {
  const MyPostsPage({super.key});
  @override ConsumerState<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends ConsumerState<MyPostsPage> {
  List<NetworkPost> _posts = [];
  bool _loading = true, _loadingMore = false, _hasMore = true;
  final _scroll = ScrollController();
  int _offset = 0;
  static const _limit = 15;

  @override void initState(){ super.initState(); _load(); _scroll.addListener(()=> { if(_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore() }); }
  @override void dispose(){ _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser?.id;
    if(uid==null) return;
    try{
      final res = await supa.from('network_posts').select('*, profiles!network_posts_user_id_fkey(display_name, photo_url, avatar_url)').eq('user_id', uid).order('created_at', ascending: false).range(0, _limit-1);
      if(!mounted) return;
      setState((){
        _posts = (res as List).map((e)=> NetworkPost.fromJson({...e, 'author_name': e['profiles']?['display_name'], 'author_avatar': e['profiles']?['photo_url']?? e['profiles']?['avatar_url']})).toList();
        _offset = _posts.length;
        _hasMore = (res as List).length == _limit;
        _loading=false;
      });
    }catch(_){ if(mounted) setState(()=> _loading=false); }
  }

  Future<void> _loadMore() async {
    if(_loadingMore ||!_hasMore) return;
    setState(()=> _loadingMore=true);
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    try{
      final res = await supa.from('network_posts').select('*, profiles!network_posts_user_id_fkey(display_name, photo_url, avatar_url)').eq('user_id', uid).order('created_at', ascending: false).range(_offset, _offset+_limit-1);
      if(!mounted) return;
      setState((){
        _posts.addAll((res as List).map((e)=> NetworkPost.fromJson({...e, 'author_name': e['profiles']?['display_name'], 'author_avatar': e['profiles']?['photo_url']?? e['profiles']?['avatar_url']})));
        _offset += (res as List).length;
        _hasMore = (res as List).length == _limit;
        _loadingMore=false;
      });
    }catch(_){ if(mounted) setState(()=> _loadingMore=false); }
  }

  @override Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id?? '';
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text('Mes publications', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)), leading: IconButton(icon: Icon(Icons.arrow_back, color: Color(0xFF0B1B3D)), onPressed: ()=> context.pop())),
      body: _loading? Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))) : _posts.isEmpty? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.post_add, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Aucune publication', style: TextStyle(fontWeight: FontWeight.bold)), Text('Vos posts apparaîtront ici', style: TextStyle(color: Colors.grey))])) : RefreshIndicator(onRefresh: _load, color: Color(0xFFD4AF37), child: CustomScrollView(controller: _scroll, slivers: [
        SliverList(delegate: SliverChildBuilderDelegate((_,i){
          if(i==_posts.length) return _loadingMore? Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))): SizedBox(height: 80);
          return Padding(padding: EdgeInsets.only(bottom: 12, top: 8, left: 12, right: 12), child: PostCard(post: _posts[i], currentProfileId: uid, onTap: ()=> context.push('/network/post/${_posts[i].id}')));
        }, childCount: _posts.length+1)),
      ])),
    );
  }
}
