import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverTab extends ConsumerStatefulWidget {
  const DiscoverTab({super.key});
  @override ConsumerState<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<DiscoverTab> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _trendingTags = [], _topUsers = [], _topPosts = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override void initState(){
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadAll();
  }
  @override void dispose(){ _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(()=> _loading=true);
    final supa = Supabase.instance.client;
    try{
      // 1. Top hashtags via post count
      final posts = await supa.from('network_posts').select('content').limit(200);
      final Map<String,int> tagCount = {};
      final reg = RegExp(r'#(\w+)', caseSensitive: false);
      for(final p in (posts as List)){
        final c = (p['content']??'') as String;
        for(final m in reg.allMatches(c)){
          final t = m.group(1)!.toLowerCase();
          tagCount[t] = (tagCount[t]??0)+1;
        }
      }
      final sortedTags = tagCount.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));

      // 2. Top users (most followers)
      List topUsers = [];
      try{
        final u = await supa.from('profiles').select('id, display_name, photo_url, avatar_url, profession, followers_count').order('followers_count', ascending: false).limit(10);
        topUsers = u as List;
      }catch(_){
        final u = await supa.from('profiles').select('id, display_name, photo_url, avatar_url, profession').limit(10);
        topUsers = u as List;
      }

      // 3. Top posts
      final tp = await supa.from('network_posts').select('id, content, image_url, media_urls, likes_count, created_at, profiles!network_posts_user_id_fkey(display_name, photo_url)').order('likes_count', ascending: false).limit(12);

      if(!mounted) return;
      setState((){
        _trendingTags = sortedTags.take(12).map((e)=> {'tag': e.key, 'count': e.value}).toList();
        _topUsers = (topUsers as List).cast<Map<String,dynamic>>();
        _topPosts = (tp as List).cast<Map<String,dynamic>>();
        _loading=false;
      });
    }catch(e){
      if(mounted) setState(()=> _loading=false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Découvrir', style: TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)), bottom: TabBar(controller: _tab, labelColor: const Color(0xFF2B5CFF), unselectedLabelColor: Colors.grey, indicatorColor: const Color(0xFF2B5CFF), tabs: const [Tab(text: 'Tendances'), Tab(text: 'Personnes'), Tab(text: 'Populaires')])),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: TextField(controller: _searchCtrl, onSubmitted: (v){
          if(v.startsWith('#')) context.push('/network/hashtag/${v.replaceAll('#','')}');
          else if(v.trim().isNotEmpty) context.push('/network/search?q=$v');
        }, decoration: InputDecoration(hintText: 'Rechercher #hashtag ou personne...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF5F7FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
        Expanded(child: _loading? const Center(child: CircularProgressIndicator(color: Color(0xFF2B5CFF))) : TabBarView(controller: _tab, children: [
          _trendsTab(),
          _peopleTab(),
          _popularTab(),
        ])),
      ]),
    );
  }

  Widget _trendsTab()=> RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Hashtags tendances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 12),
    Wrap(spacing: 8, runSpacing: 8, children: _trendingTags.map((t)=> ActionChip(label: Text('#${t['tag']} • ${t['count']}', style: const TextStyle(fontSize: 12)), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)), onPressed: ()=> context.push('/network/hashtag/${t['tag']}'))).toList()),
    if(_trendingTags.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Column(children: [Icon(Icons.tag, size: 48, color: Colors.grey.shade300), const SizedBox(height: 8), const Text('Pas encore de tendances', style: TextStyle(color: Colors.grey))]))
  ]));

  Widget _peopleTab()=> RefreshIndicator(onRefresh: _loadAll, child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _topUsers.length, itemBuilder: (_,i){
    final u = _topUsers[i];
    final avatar = u['photo_url']?? u['avatar_url'];
    return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
      leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: ClipOval(child: avatar!=null? Image.network(avatar, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.person)) : const Icon(Icons.person)))),
      title: Text(u['display_name']??'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(u['profession']??'', style: const TextStyle(fontSize: 11)),
      trailing: ElevatedButton(onPressed: ()=> context.push('/network/member/${u['id']}'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B5CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(60, 32)), child: const Text('Voir', style: TextStyle(fontSize: 11, color: Colors.white))),
      onTap: ()=> context.push('/network/member/${u['id']}'),
    ));
  }));

  Widget _popularTab()=> RefreshIndicator(onRefresh: _loadAll, child: GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _topPosts.length, itemBuilder: (_,i){
    final p = _topPosts[i];
    final prof = p['profiles'] as Map?;
    final img = p['image_url']?? (p['media_urls']!=null && (p['media_urls'] as List).isNotEmpty? (p['media_urls'] as List).first : null);
    return GestureDetector(onTap: ()=> context.push('/network/post/${p['id']}'), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if(img!=null) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(img, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(height: 120, color: Colors.grey.shade200, child: const Icon(Icons.image)))),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(prof?['display_name']??'', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1),
        const SizedBox(height: 4),
        Text(p['content']??'', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Row(children: [const Icon(Icons.favorite, size: 12, color: Colors.red), const SizedBox(width: 4), Text('${p['likes_count']??0}', style: const TextStyle(fontSize: 11))]),
      ])),
    ])));
  }));
}
