import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/network_post.dart';

class HashtagPage extends ConsumerStatefulWidget {
  final String tag;
  const HashtagPage({super.key, required this.tag});
  @override ConsumerState<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends ConsumerState<HashtagPage> with SingleTickerProviderStateMixin {
  List<NetworkPost> _posts = [];
  bool _loading = true, _following = false, _isGrid = true;
  late TabController _tab;
  String _sort = 'recent'; // recent | popular

  @override void initState(){ super.initState(); _tab=TabController(length: 2, vsync: this); _load(); _checkFollow(); }
  @override void dispose(){ _tab.dispose(); super.dispose(); }

  Future<void> _checkFollow() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if(uid==null) return;
    final r = await Supabase.instance.client.from('hashtag_follows').select().eq('user_id', uid).eq('hashtag', widget.tag.toLowerCase()).maybeSingle();
    if(mounted) setState(()=> _following = r!=null);
  }

  Future<void> _toggleFollow() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    final tag = widget.tag.toLowerCase();
    setState(()=> _following=!_following);
    try{
      if(_following) await supa.from('hashtag_follows').insert({'user_id': uid, 'hashtag': tag});
      else await supa.from('hashtag_follows').delete().eq('user_id', uid).eq('hashtag', tag);
    }catch(_){ setState(()=> _following=!_following); }
  }

  Future<void> _load() async {
    setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    try{
      var query = supa.from('network_posts').select('*, profiles!network_posts_user_id_fkey(display_name, photo_url, avatar_url), post_likes(count), comments(count)').ilike('content', '%#${widget.tag}%');
      if(_sort=='popular') query = query.order('likes_count', ascending: false);
      else query = query.order('created_at', ascending: false);

      final res = await query.limit(60);
      if(!mounted) return;
      setState((){
        _posts = (res as List).map((e){
          final prof = e['profiles'] as Map?;
          final likes = (e['post_likes'] as List?)?.isNotEmpty == true ? (e['post_likes'][0]['count'] as int? ?? 0) : e['likes_count']??0;
          final comments = (e['comments'] as List?)?.isNotEmpty == true ? (e['comments'][0]['count'] as int? ?? 0) : e['comments_count']??0;
          return NetworkPost.fromJson({
            ...e,
            'author_name': prof?['display_name'],
            'author_avatar': prof?['photo_url']??prof?['avatar_url'],
            'likes_count': likes,
            'comments_count': comments,
          });
        }).toList();
        _loading=false;
      });
    }catch(e){ if(mounted) setState(()=> _loading=false); }
  }

  String _fmt(int n){ if(n>=1000000) return '${(n/1000000).toStringAsFixed(1)}M'; if(n>=1000) return '${(n/1000).toStringAsFixed(1)}k'; return '$n'; }

  @override Widget build(BuildContext context) {
    final tag = widget.tag;
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Color(0xFF0B1B3D)), title: Text('#$tag', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)), actions: [
        IconButton(icon: Icon(_isGrid? Icons.view_list : Icons.grid_view, color: Color(0xFF0B1B3D)), onPressed: ()=> setState(()=> _isGrid=!_isGrid)),
        Padding(padding: EdgeInsets.only(right: 12), child: Center(child: Text('${_posts.length} posts', style: TextStyle(color: Colors.grey, fontSize: 13)))),
      ], bottom: TabBar(controller: _tab, onTap: (i){ _sort = i==0? 'recent':'popular'; _load(); }, labelColor: Color(0xFF2B5CFF), indicatorColor: Color(0xFF2B5CFF), tabs: [Tab(text: 'Récents'), Tab(text: 'Populaires')])),
      body: Column(children: [
        Container(color: Colors.white, padding: EdgeInsets.all(16), child: Row(children: [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF2B5CFF).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.tag, color: Color(0xFF2B5CFF), size: 28)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('#$tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('${_posts.length} publications', style: TextStyle(color: Colors.grey, fontSize: 12))])),
          ElevatedButton(onPressed: _toggleFollow, style: ElevatedButton.styleFrom(backgroundColor: _following? Colors.grey.shade200 : Color(0xFFD4AF37), foregroundColor: _following? Colors.black : Color(0xFF0B1B3D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text(_following? 'Abonné' : 'Suivre', style: TextStyle(fontWeight: FontWeight.bold))),
        ])),
        Expanded(child: _loading? Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFF))) : _posts.isEmpty? _empty() : _isGrid? _grid() : _list()),
      ]),
    );
  }

  Widget _empty()=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(Icons.tag, size: 60, color: Colors.grey)), SizedBox(height: 16), Text('#${widget.tag}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Aucun post pour ce hashtag', style: TextStyle(color: Colors.grey)), SizedBox(height: 16), ElevatedButton.icon(onPressed: ()=> context.pop(), icon: Icon(Icons.arrow_back), label: Text('Retour'), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37), foregroundColor: Color(0xFF0B1B3D)))]));
  
  Widget _grid()=> RefreshIndicator(onRefresh: _load, child: GridView.builder(padding: EdgeInsets.all(2), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2), itemCount: _posts.length, itemBuilder: (_,i)=> _gridItem(_posts[i])));
  
  Widget _list()=> RefreshIndicator(onRefresh: _load, child: ListView.builder(padding: EdgeInsets.all(12), itemCount: _posts.length, itemBuilder: (_,i){
    final p = _posts[i];
    final img = p.mediaUrls.isNotEmpty? p.mediaUrls.first : null;
    return Container(margin: EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(onTap: ()=> context.push('/network/post/${p.id}'), leading: img!=null? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(width: 50, height: 50, color: Colors.grey.shade200, child: Icon(Icons.text_fields)))) : Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.text_fields)), title: Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13)), subtitle: Text('${_fmt(p.likesCount)} likes • ${p.commentsCount} coms', style: TextStyle(fontSize: 11, color: Colors.grey))));
  }));

  Widget _gridItem(NetworkPost post){
    final img = post.mediaUrls.isNotEmpty? post.mediaUrls.first : (post as dynamic).imageUrl as String?;
    return GestureDetector(onTap: ()=> context.push('/network/post/${post.id}'), child: Stack(fit: StackFit.expand, children: [
      if(img!=null && img.isNotEmpty) Image.network(img, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(color: Colors.grey.shade200, child: Icon(Icons.broken_image))) else Container(color: Colors.grey.shade200, child: Icon(Icons.text_fields, color: Colors.grey)),
      Positioned(bottom: 6, right: 6, child: Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.favorite, size: 10, color: Colors.white), SizedBox(width: 3), Text(_fmt(post.likesCount), style: TextStyle(fontSize: 10, color: Colors.white))]))),
    ]));
  }
}
